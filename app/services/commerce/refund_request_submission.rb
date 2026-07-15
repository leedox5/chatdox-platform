require "securerandom"

module Commerce
  class RefundRequestSubmission
    class Unavailable < StandardError; end

    def self.call!(user:, order:, reason_code:, customer_note:, at: Time.current)
      ApplicationRecord.transaction do
        order.lock!
        raise Pundit::NotAuthorizedError unless order.user_id == user.id
        raise Unavailable, "only paid orders can be requested" unless order.status == "paid"
        raise Unavailable, "an open request already exists" if order.refund_requests.open.exists?

        request = order.refund_requests.create!(
          user: user,
          public_id: SecureRandom.uuid,
          status: "requested",
          reason_code: reason_code,
          customer_note: customer_note,
          requested_amount: order.total_amount,
          full_request: true,
          provider_refund_status: "not_requested"
        )
        Commerce::AuditRecorder.record!(
          actor: user,
          action: "refund_requested",
          auditable: request,
          to_state: request.status,
          reason_code: request.reason_code,
          at: at
        )
        request
      end
    rescue ActiveRecord::RecordNotUnique
      raise Unavailable, "an open request already exists"
    end
  end
end
