module Commerce
  class OrderStatusSync
    def self.call!(order:, status:, payment:, at: Time.current)
      changed = false
      result = ApplicationRecord.transaction do
        order.lock!
        next order unless order.status == "pending"

        attributes = payment.symbolize_keys
        verify_payment!(order, attributes)

        mapped_order_status = case status.to_s
        when "canceled" then "canceled"
        when "past_due", "failed" then "failed"
        end
        next order unless mapped_order_status

        mapped_transaction_status = mapped_order_status == "canceled" ? "canceled" : "past_due"
        provider_snapshot = Payments::ProviderSnapshot.build(
          provider: attributes.fetch(:provider),
          payload: attributes.fetch(:provider_payload, {})
        )

        order.payment_transaction.update!(
          provider: attributes.fetch(:provider),
          provider_payment_id: attributes.fetch(:provider_payment_id),
          order_id: order.public_id,
          status: mapped_transaction_status,
          amount: attributes.fetch(:amount, order.total_amount),
          currency: attributes.fetch(:currency, order.currency),
          provider_payload: provider_snapshot,
          provider_status: provider_snapshot["status"],
          provider_observed_at: at
        )
        order.transition_to!(mapped_order_status, finalized_at: at, last_provider_event_at: at)
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

    def self.verify_payment!(order, attributes)
      checks = {
        provider: order.provider,
        order_id: order.public_id,
        amount: order.total_amount,
        currency: order.currency
      }
      checks.each do |key, expected|
        actual = attributes.fetch(key)
        unless actual.to_s == expected.to_s
          raise Commerce::OrderFinalizer::VerificationError, "payment #{key} mismatch"
        end
      end
      if attributes[:provider_payment_id].blank?
        raise Commerce::OrderFinalizer::VerificationError, "provider payment ID is missing"
      end
    end
  end
end
