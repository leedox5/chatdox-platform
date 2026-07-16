require "test_helper"

class PaymentsGatewayVerificationTest < ActiveSupport::TestCase
  test "PortOne adapter rejects payment id amount currency and unpaid status mismatches" do
    valid = {
      "id" => "test-order",
      "amount" => { "total" => 7_700 },
      "currency" => "KRW",
      "status" => "PAID"
    }
    client = Struct.new(:payment) do
      def get_payment(_payment_id)
        payment
      end
    end

    assert_equal valid, Payments::PortoneGateway.new(client: client.new(valid)).verify_payment!(
      payment_id: "test-order", expected_amount: 7_700, expected_currency: "KRW"
    )
    {
      Payments::PortoneGateway::PaymentIdMismatchError => valid.merge("id" => "other-order"),
      Payments::PortoneGateway::AmountMismatchError => valid.merge("amount" => { "total" => 1 }),
      Payments::PortoneGateway::CurrencyMismatchError => valid.merge("currency" => "USD"),
      Payments::PortoneGateway::UnpaidStatusError => valid.merge("status" => "FAILED")
    }.each do |error_class, response|
      assert_raises(error_class) do
        Payments::PortoneGateway.new(client: client.new(response)).verify_payment!(
          payment_id: "test-order", expected_amount: 7_700, expected_currency: "KRW"
        )
      end
    end
  end
end
