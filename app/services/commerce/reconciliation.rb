module Commerce
  class Reconciliation
    DEFAULT_STALE_AFTER = 30.minutes
    Issue = Data.define(:code, :order_public_id, :provider, :status)
    Report = Data.define(:issues, :checked_at) do
      def ok?
        issues.empty?
      end
    end

    def self.call(stale_after: DEFAULT_STALE_AFTER, at: Time.current, log: true)
      new(stale_after: stale_after, at: at, log: log).call
    end

    def initialize(stale_after:, at:, log:)
      @stale_after = stale_after
      @at = at
      @log = log
      @issues = []
    end

    def call
      orders = Order.includes(order_items: :license, payment_transaction: :subscription).find_each
      orders.each { |order| inspect_order(order) }
      inspect_license_overlaps
      log_issues if @log
      Report.new(issues: @issues.freeze, checked_at: @at)
    end

    private

    def inspect_order(order)
      transaction = order.payment_transaction
      add_issue(:paid_without_transaction, order) if order.status == "paid" && transaction.blank?
      add_issue(:paid_without_license, order) if order.status == "paid" && order.licenses.empty?
      add_issue(:stale_pending, order) if stale_pending?(order)
      add_issue(:terminal_order_with_license, order) if %w[failed canceled].include?(order.status) && order.licenses.any?
      add_issue(:payment_amount_mismatch, order) if transaction && transaction.amount != order.total_amount
      add_issue(:order_item_total_mismatch, order) unless order_item_totals_match?(order)
      add_issue(:purchase_transaction_with_subscription, order) if transaction&.subscription_id.present?
      add_issue(:processed_payment_unfinalized, order) if processed_but_unfinalized?(order, transaction)
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
      return false if order.status == "paid" || transaction.blank?

      transaction.status == "active" || successful_provider_status?(transaction.provider_payload)
    end

    def successful_provider_status?(payload)
      %w[DONE PAID].include?(payload.to_h["status"])
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
