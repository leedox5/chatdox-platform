module Payments
  class PortoneGateway
    PROVIDER = "portone"
    PAID_STATUS = "PAID"

    def initialize(client: Portone::Client)
      @client = client
    end

    def provider
      PROVIDER
    end

    def fetch_payment!(payment_id)
      @client.get_payment(payment_id)
    end

    def verify_payment!(payment_id:, expected_amount:, expected_currency:)
      payment = fetch_payment!(payment_id)
      provider_payment_id = payment["id"] || payment["paymentId"]
      paid_amount = payment.dig("amount", "total").to_i

      raise "PortOne payment id mismatch" unless provider_payment_id == payment_id
      raise "PortOne payment amount mismatch" unless paid_amount == expected_amount
      raise "PortOne payment currency mismatch" unless payment["currency"] == expected_currency
      raise "PortOne payment is not paid" unless payment["status"] == PAID_STATUS

      payment
    end
  end
end
