module Payments
  class TossGateway
    PROVIDER = "toss"

    def provider
      PROVIDER
    end

    def confirm_payment!(payment_key:, order_id:, amount:)
      payment = TossPayments::Client.post_json(
        "/v1/payments/confirm",
        {
          paymentKey: payment_key,
          orderId: order_id,
          amount: amount
        }
      )

      raise "Toss payment amount mismatch" unless payment["totalAmount"].to_i == amount
      raise "Toss payment is not done" unless payment["status"] == "DONE"

      payment
    end
  end
end
