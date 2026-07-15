module ExternalAccess
  class DisconnectRequest
    class Unavailable < StandardError; end

    def self.call!(user:, link:, at: Time.current)
      ApplicationRecord.transaction do
        link.lock!
        raise Pundit::NotAuthorizedError unless link.user_id == user.id
        raise Unavailable, "link is already disabled" if link.status == "disabled"

        live_grants = link.external_access_grants.live.lock.to_a
        previous = link.status
        if live_grants.any?
          link.update!(status: "change_requested", change_requested_at: at)
          live_grants.each { |grant| ExternalAccess::DueProcessor.mark_revoke_due!(grant: grant, at: at, actor: user) }
          action = "link_change_requested"
          reason = "customer_disconnect_pending_revoke"
        else
          link.update!(status: "disabled", disabled_at: at)
          action = "link_disabled"
          reason = "customer_disconnect"
        end
        ExternalAccess::EventRecorder.record!(
          actor: user,
          action: action,
          subject: link,
          from_state: previous,
          to_state: link.status,
          reason_code: reason,
          at: at
        )
        link
      end
    end
  end
end
