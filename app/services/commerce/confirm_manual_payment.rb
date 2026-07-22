module Commerce
  # Admin counterpart to the PG verification step BillingController runs for
  # PortOne: for a manual bank-transfer order there's no gateway to call, so
  # the admin manually checking the bank statement *is* the verification. This
  # builds the same "payment" attributes shape OrderFinalizer expects from a
  # real gateway response and hands off to it so license issuance, the payment
  # transaction record, and the order state transition all go through the
  # exact same path a PortOne payment would.
  class ConfirmManualPayment
    class Unavailable < StandardError; end

    def self.call!(order:, actor:, at: Time.current)
      new(order: order, actor: actor, at: at).call!
    end

    def initialize(order:, actor:, at:)
      @order = order
      @actor = actor
      @at = at
    end

    def call!
      raise Pundit::NotAuthorizedError unless @actor&.admin?
      raise Unavailable, "not a manual bank transfer order" unless @order.provider == Order::MANUAL_PROVIDER
      raise Unavailable, "order is not pending" unless @order.status == "pending"

      order = Commerce::OrderFinalizer.call!(order: @order, payment: manual_payment_attributes, at: @at)
      Commerce::AuditRecorder.record!(
        actor: @actor,
        action: "manual_payment_confirmed",
        auditable: order,
        from_state: "pending",
        to_state: order.status,
        reason_code: "admin_confirmed_bank_transfer",
        at: @at
      )
      order
    end

    private

    def manual_payment_attributes
      {
        provider: Order::MANUAL_PROVIDER,
        # Keyed off the order's own public_id (already globally unique) rather
        # than actor/timestamp, so two confirmations landing in the same
        # second can't collide against the provider+provider_payment_id
        # uniqueness constraint on payment_transactions.
        provider_payment_id: "manual:#{@order.public_id}",
        order_id: @order.public_id,
        amount: @order.total_amount,
        currency: @order.currency,
        provider_payload: { status: "manually_confirmed" }
      }
    end
  end
end
