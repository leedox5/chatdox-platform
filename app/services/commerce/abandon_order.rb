module Commerce
  class AbandonOrder
    class Unsafe < StandardError; end

    def self.call!(order:, actor:, at: Time.current)
      ApplicationRecord.transaction do
        order.lock!
        raise Pundit::NotAuthorizedError unless actor&.admin?

        assessment = Commerce::PendingOrderAssessment.call(order: order, at: at)
        raise Unsafe, assessment.reason_code unless assessment.safe_to_abandon

        previous_status = order.status
        order.transition_to!("abandoned", abandoned_at: at, finalized_at: at)
        Commerce::AuditRecorder.record!(
          actor: actor,
          action: "order_abandoned",
          auditable: order,
          from_state: previous_status,
          to_state: order.status,
          reason_code: assessment.reason_code,
          at: at
        )
        order
      end
    end
  end
end
