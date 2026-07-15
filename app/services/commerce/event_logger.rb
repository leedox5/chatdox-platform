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
      commerce.abandoned_provider_success_conflict
      commerce.reconciliation_anomaly.paid_without_transaction
      commerce.reconciliation_anomaly.paid_without_license
      commerce.reconciliation_anomaly.stale_pending
      commerce.reconciliation_anomaly.terminal_order_with_license
      commerce.reconciliation_anomaly.payment_amount_mismatch
      commerce.reconciliation_anomaly.order_item_total_mismatch
      commerce.reconciliation_anomaly.overlapping_license
      commerce.reconciliation_anomaly.purchase_transaction_with_subscription
      commerce.reconciliation_anomaly.processed_payment_unfinalized
      commerce.reconciliation_anomaly.abandoned_provider_success_conflict
      commerce.reconciliation_anomaly.paid_order_open_refund
      commerce.reconciliation_anomaly.refund_without_provider_confirmation
      commerce.reconciliation_anomaly.refunded_license_policy_unresolved
      commerce.reconciliation_anomaly.duplicate_open_refund_requests
      commerce.reconciliation_anomaly.active_license_verified_link_missing_grant
      commerce.reconciliation_anomaly.invited_acceptance_overdue
      commerce.reconciliation_anomaly.expired_license_live_grant
      commerce.reconciliation_anomaly.revoke_due_overdue
      commerce.reconciliation_anomaly.revoked_grant_open_revoke_task
      commerce.reconciliation_anomaly.live_grant_inactive_link
      commerce.reconciliation_anomaly.duplicate_github_identity
      commerce.reconciliation_anomaly.multiple_active_product_grants
      commerce.reconciliation_anomaly.task_grant_state_mismatch
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
