module Commerce
  class EventLogger
    EVENTS = %w[
      commerce.gate_configuration_mismatch
      commerce.payment_verification_failed
      commerce.order_finalization_failed
      commerce.order_finalized
      commerce.order_status_changed
      commerce.webhook_processing_failed
      commerce.callback_processing_failed
      commerce.reconciliation_anomaly.paid_without_transaction
      commerce.reconciliation_anomaly.paid_without_license
      commerce.reconciliation_anomaly.stale_pending
      commerce.reconciliation_anomaly.terminal_order_with_license
      commerce.reconciliation_anomaly.payment_amount_mismatch
      commerce.reconciliation_anomaly.order_item_total_mismatch
      commerce.reconciliation_anomaly.overlapping_license
      commerce.reconciliation_anomaly.purchase_transaction_with_subscription
      commerce.reconciliation_anomaly.processed_payment_unfinalized
    ].freeze

    def self.log(event:, provider:, order: nil, status:, at: Time.current, level: :warn)
      raise ArgumentError, "unknown commerce event" unless EVENTS.include?(event.to_s)

      message = [
        "event=#{event}",
        "provider=#{provider.presence || 'unknown'}",
        "order_id=#{order&.public_id || '-'}",
        "status=#{status}",
        "occurred_at=#{at.utc.iso8601}"
      ].join(" ")
      Rails.logger.public_send(level, message)
    end
  end
end
