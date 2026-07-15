module Commerce
  class OrderStatusSync
    def self.call!(order:, status:, payment:, at: Time.current)
      changed = false
      result = ApplicationRecord.transaction do
        order.lock!
        next order if order.status == "paid"

        mapped_order_status = case status.to_s
        when "canceled" then "canceled"
        when "past_due", "failed" then "failed"
        end
        next order unless mapped_order_status

        mapped_transaction_status = mapped_order_status == "canceled" ? "canceled" : "past_due"
        attributes = payment.symbolize_keys

        order.payment_transaction.update!(
          provider: attributes.fetch(:provider),
          provider_payment_id: attributes.fetch(:provider_payment_id),
          order_id: order.public_id,
          status: mapped_transaction_status,
          amount: attributes.fetch(:amount, order.total_amount),
          currency: attributes.fetch(:currency, order.currency),
          provider_payload: attributes.fetch(:provider_payload, {})
        )
        order.transition_to!(mapped_order_status, finalized_at: at)
        changed = true
        order
      end

      if changed
        Commerce::EventLogger.log(
          event: "commerce.order_status_changed",
          provider: order.provider,
          order: order,
          status: order.status,
          at: at,
          level: :info
        )
      end
      result
    end
  end
end
