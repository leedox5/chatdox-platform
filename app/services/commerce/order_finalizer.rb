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

        if @order.status == "paid"
          verify_finalized_payment_id!
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
            provider_payload: @payment.fetch(:provider_payload, {})
          )

          @order.order_items.includes(:product).each do |item|
            Commerce::LicenseScheduler.create_for!(
              user: @order.user,
              order_item: item,
              requested_start_on: @order.requested_start_on,
              at: @at
            )
          end

          @order.transition_to!("paid", paid_at: @at, finalized_at: @at)
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
