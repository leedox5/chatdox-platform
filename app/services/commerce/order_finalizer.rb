module Commerce
  class OrderFinalizer
    class VerificationError < StandardError; end

    def self.call!(order:, payment:, at: Time.current)
      new(order: order, payment: payment, at: at).call!
    end

    def initialize(order:, payment:, at:)
      @order = order
      @payment = payment.symbolize_keys
      @at = at
    end

    def call!
      finalized = false
      result = ApplicationRecord.transaction do
        @order.lock!
        verify_payment!

        if @order.status == "abandoned"
          record_late_success!
        elsif @order.status == "paid"
          verify_finalized_payment_id!
          observe_provider_event!
        else
          raise VerificationError, "order is not pending" unless @order.status == "pending"

          transaction = @order.payment_transaction
          transaction.update!(
            provider: @payment.fetch(:provider),
            provider_payment_id: @payment.fetch(:provider_payment_id),
            order_id: @order.public_id,
            status: "active",
            amount: @payment.fetch(:amount),
            currency: @payment.fetch(:currency),
            provider_payload: provider_snapshot,
            provider_status: provider_status,
            provider_observed_at: @at
          )

          @order.order_items.includes(:product).each do |item|
            Commerce::LicenseScheduler.create_for!(
              user: @order.user,
              order_item: item,
              requested_start_on: @order.requested_start_on,
              at: @at
            )
          end

          @order.transition_to!("paid", paid_at: @at, finalized_at: @at, last_provider_event_at: @at)
          finalized = true
        end
        @order
      end

      if finalized
        Commerce::EventLogger.log(
          event: "commerce.order_finalized",
          provider: @order.provider,
          order: @order,
          status: @order.status,
          at: @at,
          level: :info
        )
      end
      result
    rescue VerificationError
      log_failure("commerce.payment_verification_failed")
      raise
    rescue StandardError
      log_failure("commerce.order_finalization_failed")
      raise
    end

    private

    def verify_payment!
      checks = {
        provider: @order.provider,
        order_id: @order.public_id,
        amount: @order.total_amount,
        currency: @order.currency
      }
      checks.each do |key, expected|
        actual = @payment.fetch(key)
        raise VerificationError, "payment #{key} mismatch" unless actual.to_s == expected.to_s
      end
      raise VerificationError, "provider payment ID is missing" if @payment[:provider_payment_id].blank?
    end

    def verify_finalized_payment_id!
      return if @order.payment_transaction.provider_payment_id == @payment.fetch(:provider_payment_id)

      raise VerificationError, "order was finalized with a different payment"
    end

    def observe_provider_event!
      @order.payment_transaction.update!(provider_status: provider_status, provider_observed_at: @at)
      @order.update!(last_provider_event_at: @at)
    end

    def record_late_success!
      @order.payment_transaction.update!(
        provider_status: provider_status,
        provider_observed_at: @at,
        provider_payload: provider_snapshot
      )
      @order.update!(last_provider_event_at: @at)
      Commerce::AuditRecorder.record!(
        actor: nil,
        action: "late_provider_success_observed",
        auditable: @order,
        from_state: @order.status,
        to_state: @order.status,
        reason_code: "provider_success_after_abandoned",
        at: @at
      )
      Commerce::EventLogger.log(
        event: "commerce.abandoned_provider_success_conflict",
        provider: @order.provider,
        order: @order,
        status: @order.status,
        at: @at
      )
    end

    def provider_status
      provider_snapshot["status"]
    end

    def provider_snapshot
      @provider_snapshot ||= Payments::ProviderSnapshot.build(
        provider: @payment.fetch(:provider),
        payload: @payment.fetch(:provider_payload, {})
      )
    end

    def log_failure(event)
      Commerce::EventLogger.log(
        event: event,
        provider: @order.provider,
        order: @order,
        status: @order.status,
        at: @at
      )
    end
  end
end
