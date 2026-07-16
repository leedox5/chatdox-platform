module Commerce
  class Reconciliation
    DEFAULT_STALE_AFTER = 30.minutes
    Issue = Data.define(:code, :order_public_id, :provider, :status)
    Report = Data.define(:issues, :checked_at, :pending_summary) do
      def ok?
        issues.empty?
      end
    end

    def self.call(stale_after: DEFAULT_STALE_AFTER, at: Time.current, log: true, include_external_access: true)
      new(
        stale_after: stale_after,
        at: at,
        log: log,
        include_external_access: include_external_access
      ).call
    end

    def initialize(stale_after:, at:, log:, include_external_access: true)
      @stale_after = stale_after
      @at = at
      @log = log
      @include_external_access = include_external_access
      @issues = []
    end

    def call
      orders = Order.includes(:refund_requests, :payment_transaction, order_items: :license).find_each
      orders.each { |order| inspect_order(order) }
      inspect_license_overlaps
      inspect_duplicate_open_refunds
      inspect_external_access if @include_external_access
      log_issues if @log
      Report.new(issues: @issues.freeze, checked_at: @at, pending_summary: pending_summary)
    end

    private

    def inspect_order(order)
      transaction = order.payment_transaction
      add_issue(:paid_without_transaction, order) if order.status == "paid" && transaction.blank?
      add_issue(:paid_without_license, order) if order.status == "paid" && order.licenses.empty?
      add_issue(:stale_pending, order) if stale_pending?(order)
      add_issue(:terminal_order_with_license, order) if %w[failed canceled abandoned].include?(order.status) && order.licenses.any?
      add_issue(:payment_amount_mismatch, order) if transaction && transaction.amount != order.total_amount
      add_issue(:order_item_total_mismatch, order) unless order_item_totals_match?(order)
      add_issue(:processed_payment_unfinalized, order) if processed_but_unfinalized?(order, transaction)
      add_issue(:abandoned_provider_success_conflict, order) if abandoned_success_conflict?(order, transaction)
      inspect_refunds(order)
    end

    def stale_pending?(order)
      order.status == "pending" && order.payment_requested_at < (@at - @stale_after)
    end

    def order_item_totals_match?(order)
      items = order.order_items
      items.sum(&:supply_amount) == order.supply_amount &&
        items.sum(&:vat_amount) == order.vat_amount &&
        items.sum(&:total_amount) == order.total_amount
    end

    def processed_but_unfinalized?(order, transaction)
      return false if %w[paid abandoned].include?(order.status) || transaction.blank?

      transaction.status == "active" || successful_provider_status?(transaction.provider_payload)
    end

    def successful_provider_status?(payload)
      %w[DONE PAID].include?(payload.to_h["status"])
    end

    def abandoned_success_conflict?(order, transaction)
      order.status == "abandoned" && transaction.present? && (
        %w[DONE PAID].include?(transaction.provider_status) ||
        successful_provider_status?(transaction.provider_payload) ||
        transaction.status == "active"
      )
    end

    def inspect_refunds(order)
      requests = order.refund_requests.to_a
      add_issue(:paid_order_open_refund, order) if order.status == "paid" && requests.any?(&:open?)
      requests.select { |request| request.status == "refunded" }.each do |request|
        add_issue(:refund_without_provider_confirmation, order) unless request.external_refund_confirmed?
        add_issue(:refunded_license_policy_unresolved, order) if request.external_refund_confirmed? && order.licenses.any?
      end
    end

    def inspect_duplicate_open_refunds
      RefundRequest.open.group(:order_id).having("COUNT(*) > 1").count.each_key do |order_id|
        add_issue(:duplicate_open_refund_requests, Order.find_by(id: order_id))
      end
    end

    def inspect_external_access
      inspect_missing_external_grants
      inspect_external_grants
      inspect_duplicate_external_identities
      inspect_duplicate_active_grants
      inspect_external_task_consistency
    end

    def inspect_missing_external_grants
      ExternalAccountLink.verified.includes(user: { licenses: :product }).find_each do |link|
        link.user.licenses.select { |license| license.product.code == "chatdox" && license.active_at?(@at) }.each do |license|
          next if ExternalAccessGrant.live.exists?(user: link.user, product: license.product)

          add_external_issue(:active_license_verified_link_missing_grant, link, link.status)
        end
      end
    end

    def inspect_external_grants
      ExternalAccessGrant.includes(:external_account_link, :license, user: :licenses).find_each do |grant|
        active_entitlement = grant.user.licenses.any? do |license|
          license.product_id == grant.product_id && license.active_at?(@at)
        end
        if grant.status == "invited" && grant.invited_at && grant.invited_at < @at - 7.days
          add_external_issue(:invited_acceptance_overdue, grant, grant.status)
        end
        if %w[invited active].include?(grant.status) && !active_entitlement
          add_external_issue(:expired_license_live_grant, grant, grant.status)
        end
        if grant.status == "revoke_due" && grant.revoke_due_at && grant.revoke_due_at < @at - 1.day
          add_external_issue(:revoke_due_overdue, grant, grant.status)
        end
        if ExternalAccessGrant::LIVE_STATUSES.include?(grant.status) && grant.external_account_link.status != "verified"
          add_external_issue(:live_grant_inactive_link, grant, grant.status)
        end
        next unless grant.status == "revoked"

        open_revoke = grant.external_access_tasks.open.where(task_type: %w[revoke_access confirm_revocation]).exists?
        add_external_issue(:revoked_grant_open_revoke_task, grant, grant.status) if open_revoke
      end
    end

    def inspect_duplicate_external_identities
      duplicate_username = ExternalAccountLink.available.group(:provider, :normalized_username).having("COUNT(*) > 1").count
      duplicate_uid = ExternalAccountLink.available.where.not(external_uid: nil).group(:provider, :external_uid)
        .having("COUNT(*) > 1").count
      return if duplicate_username.empty? && duplicate_uid.empty?

      add_external_issue(:duplicate_github_identity, ExternalAccountLink.available.first, "duplicate")
    end

    def inspect_duplicate_active_grants
      duplicates = ExternalAccessGrant.where(status: "active").group(:user_id, :product_id).having("COUNT(*) > 1").count
      duplicates.each_key do |user_id, product_id|
        grant = ExternalAccessGrant.find_by(user_id: user_id, product_id: product_id, status: "active")
        add_external_issue(:multiple_active_product_grants, grant, grant&.status || "duplicate")
      end
    end

    def inspect_external_task_consistency
      expected = {
        "send_invite" => "grant_due",
        "confirm_acceptance" => "invited",
        "revoke_access" => "revoke_due",
        "confirm_revocation" => "revoke_due"
      }
      ExternalAccessTask.open.includes(:external_access_grant, :external_account_link).find_each do |task|
        mismatched = if expected.key?(task.task_type)
          task.external_access_grant&.status != expected.fetch(task.task_type)
        elsif task.task_type == "verify_account"
          task.external_account_link.status != "pending_verification"
        else
          false
        end
        add_external_issue(:task_grant_state_mismatch, task, task.status) if mismatched
      end
    end

    def pending_summary
      pending = Order.where(status: "pending")
      stale = pending.where("payment_requested_at < ?", @at - @stale_after).count
      { fresh: pending.count - stale, stale: stale }.freeze
    end

    def inspect_license_overlaps
      License.not_canceled.includes(order_item: :order).order(:user_id, :product_id, :starts_on)
        .group_by { |license| [ license.user_id, license.product_id ] }
        .each_value do |licenses|
          licenses.each_cons(2) do |previous, current|
            next if current.starts_on > previous.last_usable_on

            order = current.order_item&.order || previous.order_item&.order
            add_issue(:overlapping_license, order, provider: order&.provider, status: current.effective_status(at: @at))
          end
        end
    end

    def add_issue(code, order = nil, provider: order&.provider, status: order&.status || "unknown")
      @issues << Issue.new(
        code: code.to_s,
        order_public_id: order&.public_id || "-",
        provider: provider.presence || "unknown",
        status: status
      )
    end

    def add_external_issue(code, subject, status)
      @issues << Issue.new(
        code: code.to_s,
        order_public_id: subject&.public_id || "-",
        provider: "github",
        status: status
      )
    end

    def log_issues
      @issues.each do |issue|
        Commerce::EventLogger.log(
          event: "commerce.reconciliation_anomaly.#{issue.code}",
          provider: issue.provider,
          order: Order.find_by(public_id: issue.order_public_id),
          status: issue.status,
          at: @at
        )
      end
    end
  end
end
