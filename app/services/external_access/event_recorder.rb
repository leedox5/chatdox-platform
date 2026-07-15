module ExternalAccess
  class EventRecorder
    def self.record!(actor:, action:, subject:, link: nil, grant: nil, task: nil,
      from_state: nil, to_state: nil, reason_code: nil, evidence_note: nil, at: Time.current)
      link ||= subject if subject.is_a?(ExternalAccountLink)
      grant ||= subject if subject.is_a?(ExternalAccessGrant)
      task ||= subject if subject.is_a?(ExternalAccessTask)

      ExternalAccessEvent.create!(
        actor: actor,
        action: action,
        subject: subject,
        external_account_link: link || grant&.external_account_link || task&.external_account_link,
        external_access_grant: grant || task&.external_access_grant,
        external_access_task: task,
        from_state: from_state,
        to_state: to_state,
        reason_code: reason_code,
        evidence_note: evidence_note,
        occurred_at: at
      )
    end
  end
end
