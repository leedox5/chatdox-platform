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

    # Same "no provider evidence this might have actually succeeded" check `call`
    # uses for safe_to_abandon, but without the staleness gate -- for callers that
    # already have a stronger, immediate signal of intent (the order's own owner,
    # in the current authenticated request, replacing it with a new choice) instead
    # of inferring abandonment from elapsed time.
    def self.evidence_free?(order:)
      new(order: order, at: Time.current, stale_after: DEFAULT_STALE_AFTER).evidence_free?
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
      safe = stale && evidence_free?

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

    def evidence_free?
      transaction = @order.payment_transaction
      actual_payment_id = transaction&.provider_payment_id.present? && !transaction.provider_payment_id.start_with?("pending:")
      success = transaction.present? && (
        SUCCESS_STATUSES.include?(transaction.provider_status) ||
        SUCCESS_STATUSES.include?(transaction.provider_payload.to_h["status"]) ||
        transaction.status == "active"
      )
      transaction&.status == "pending" && !actual_payment_id && !success &&
        transaction.provider_status.blank? && transaction.provider_payload.to_h.empty?
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
