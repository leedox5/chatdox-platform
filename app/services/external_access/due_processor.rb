module ExternalAccess
  class DueProcessor
    Result = Data.define(:grants_created, :revokes_marked, :tasks_created)

    def self.call!(at: Time.current)
      new(at: at).call!
    end

    def self.mark_revoke_due!(grant:, at: Time.current, actor: nil)
      grant.lock!
      return grant if grant.status == "revoke_due"
      return grant if grant.status == "revoked"

      previous = grant.status
      grant.transition_to!("revoke_due", { revoke_due_at: at })
      EventRecorder.record!(
        actor: actor,
        action: "grant_revoke_due",
        subject: grant,
        from_state: previous,
        to_state: grant.status,
        reason_code: grant.external_account_link.status == "verified" ? "license_expired" : "link_change_or_disable",
        at: at
      )
      TaskFactory.ensure!(
        task_type: "revoke_access",
        link: grant.external_account_link,
        grant: grant,
        due_at: at,
        actor: actor
      )
      grant
    end

    def initialize(at:)
      @at = at
      @grants_created = 0
      @revokes_marked = 0
      @tasks_before = ExternalAccessTask.count
    end

    def call!
      ApplicationRecord.transaction do
        create_due_grants
        mark_due_revocations
      end
      Result.new(
        grants_created: @grants_created,
        revokes_marked: @revokes_marked,
        tasks_created: ExternalAccessTask.count - @tasks_before
      )
    end

    private

    def create_due_grants
      active_chatdox_licenses.each do |license|
        link = license.user.external_account_links.verified.first
        next unless link
        next if ExternalAccessGrant.where(user: license.user, product: license.product).where.not(status: "revoked").exists?

        grant = ExternalAccessGrant.create!(
          user: license.user,
          product: license.product,
          license: license,
          external_account_link: link,
          repository_key: "chatdox_lab",
          status: "grant_due"
        )
        @grants_created += 1
        EventRecorder.record!(
          actor: nil,
          action: "grant_due",
          subject: grant,
          from_state: nil,
          to_state: grant.status,
          reason_code: "license_active",
          at: @at
        )
        TaskFactory.ensure!(task_type: "send_invite", link: link, grant: grant, due_at: @at)
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
        next
      end
    end

    def mark_due_revocations
      ExternalAccessGrant.where(status: %w[grant_due invited active]).includes(:user, :product, :external_account_link).find_each do |grant|
        entitlement_active = grant.user.licenses.where(product: grant.product).not_canceled.any? { |license| license.active_at?(@at) }
        next if entitlement_active && grant.external_account_link.status == "verified"

        self.class.mark_revoke_due!(grant: grant, at: @at)
        @revokes_marked += 1
      end
    end

    def active_chatdox_licenses
      License.for_product("chatdox").not_canceled.includes(:user, :product).select { |license| license.active_at?(@at) }
    end
  end
end
