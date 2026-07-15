module ExternalAccess
  class LinkSubmission
    class Unavailable < StandardError; end

    def self.call!(user:, username:, at: Time.current)
      ApplicationRecord.transaction do
        user.lock!
        raise Unavailable, "an account link already exists" if user.external_account_links.available.exists?

        link = user.external_account_links.create!(
          provider: "github",
          username: username,
          status: "pending_verification"
        )
        ExternalAccess::EventRecorder.record!(
          actor: user,
          action: "link_requested",
          subject: link,
          from_state: nil,
          to_state: link.status,
          reason_code: "customer_submission",
          at: at
        )
        ExternalAccess::TaskFactory.ensure!(task_type: "verify_account", link: link, due_at: at, actor: user)
        link
      end
    end
  end
end
