module ExternalAccess
  class AccountChangeRequest
    class Unavailable < StandardError; end

    def self.call!(user:, current_link:, username:, at: Time.current)
      ApplicationRecord.transaction do
        user.lock!
        current_link.lock!
        raise Pundit::NotAuthorizedError unless current_link.user_id == user.id
        raise Unavailable, "link is not changeable" unless current_link.status == "verified"
        raise Unavailable, "a replacement already exists" if current_link.replacement_link.present?

        replacement = user.external_account_links.create!(
          provider: "github",
          username: username,
          status: "pending_verification",
          replaces_link: current_link
        )
        current_link.update!(status: "change_requested", change_requested_at: at)
        ExternalAccess::EventRecorder.record!(
          actor: user,
          action: "link_change_requested",
          subject: current_link,
          from_state: "verified",
          to_state: current_link.status,
          reason_code: "customer_account_change",
          at: at
        )
        ExternalAccess::EventRecorder.record!(
          actor: user,
          action: "link_requested",
          subject: replacement,
          from_state: nil,
          to_state: replacement.status,
          reason_code: "replacement_candidate",
          at: at
        )
        ExternalAccess::TaskFactory.ensure!(
          task_type: "process_account_change",
          link: replacement,
          product: current_link.external_access_grants.first&.product,
          due_at: at,
          actor: user
        )
        replacement
      end
    end
  end
end
