module Payments
  class PortoneGateway
    class PaymentVerificationError < StandardError; end
    class PaymentIdMismatchError < PaymentVerificationError; end
    class AmountMismatchError < PaymentVerificationError; end
    class CurrencyMismatchError < PaymentVerificationError; end
    class UnpaidStatusError < PaymentVerificationError; end

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

      unless provider_payment_id == payment_id
        raise PaymentIdMismatchError, "PortOne payment id mismatch"
      end
      unless paid_amount == expected_amount
        raise AmountMismatchError, "PortOne payment amount mismatch"
      end
      unless payment["currency"] == expected_currency
        raise CurrencyMismatchError, "PortOne payment currency mismatch"
      end
      unless payment["status"] == PAID_STATUS
        raise UnpaidStatusError, "PortOne payment is not paid"
      end

      payment
    end
  end
end
