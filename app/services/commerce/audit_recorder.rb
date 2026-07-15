module Commerce
  class AuditRecorder
    def self.record!(actor:, action:, auditable:, from_state: nil, to_state: nil, reason_code: nil, at: Time.current)
      CommerceAuditEvent.create!(
        actor: actor,
        action: action,
        auditable: auditable,
        from_state: from_state,
        to_state: to_state,
        reason_code: reason_code,
        occurred_at: at
      )
    end
  end
end
