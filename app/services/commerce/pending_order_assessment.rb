module Commerce
  class PendingOrderAssessment
    DEFAULT_STALE_AFTER = 30.minutes
    SUCCESS_STATUSES = %w[DONE PAID].freeze
    Result = Data.define(
      :classification, :stale, :safe_to_abandon, :provider_confirmation_required,
      :provider_payment_id_present, :success_evidence, :last_event_at, :reason_code
    )

    def self.call(order:, at: Time.current, stale_after: configured_stale_after)
      new(order: order, at: at, stale_after: stale_after).call
    end

    def self.configured_stale_after
      minutes = Integer(ENV.fetch("COMMERCE_PENDING_STALE_MINUTES", "30"), 10)
      (minutes.positive? ? minutes : 30).minutes
    rescue ArgumentError
      DEFAULT_STALE_AFTER
    end

    def initialize(order:, at:, stale_after:)
      @order = order
      @at = at
      @stale_after = stale_after
    end

    def call
      stale = @order.status == "pending" && @order.payment_requested_at < (@at - @stale_after)
      transaction = @order.payment_transaction
      actual_payment_id = transaction&.provider_payment_id.present? && !transaction.provider_payment_id.start_with?("pending:")
      success = transaction.present? && (
        SUCCESS_STATUSES.include?(transaction.provider_status) ||
        SUCCESS_STATUSES.include?(transaction.provider_payload.to_h["status"]) ||
        transaction.status == "active"
      )
      safe = stale && transaction&.status == "pending" && !actual_payment_id && !success &&
        transaction.provider_status.blank? && transaction.provider_payload.to_h.empty?

      Result.new(
        classification: stale ? "stale" : "fresh",
        stale: stale,
        safe_to_abandon: safe,
        provider_confirmation_required: stale && !safe,
        provider_payment_id_present: actual_payment_id,
        success_evidence: success,
        last_event_at: @order.last_provider_event_at || transaction&.provider_observed_at,
        reason_code: reason_code(stale, safe, actual_payment_id, success, transaction)
      )
    end

    private

    def reason_code(stale, safe, actual_payment_id, success, transaction)
      return "fresh_pending" unless stale
      return "safe_abandoned_candidate" if safe
      return "provider_success_evidence" if success
      return "provider_payment_id_present" if actual_payment_id
      return "payment_transaction_missing" unless transaction

      "provider_confirmation_required"
    end
  end
end
