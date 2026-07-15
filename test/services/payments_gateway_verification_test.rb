require "test_helper"

class PaymentsGatewayVerificationTest < ActiveSupport::TestCase
  test "Toss adapter accepts done payment and rejects amount or status mismatch" do
    gateway = Payments::TossGateway.new
    valid = {
      "paymentKey" => "test-payment",
      "orderId" => "test-order",
      "totalAmount" => 7_700,
      "currency" => "KRW",
      "status" => "DONE"
    }

    with_singleton_method(TossPayments::Client, :post_json, ->(_path, _body) { valid }) do
      assert_equal valid, gateway.confirm_payment!(payment_key: "test-payment", order_id: "test-order", amount: 7_700)
    end
    with_singleton_method(TossPayments::Client, :post_json, ->(_path, _body) { valid.merge("totalAmount" => 1) }) do
      assert_raises(RuntimeError) do
        gateway.confirm_payment!(payment_key: "test-payment", order_id: "test-order", amount: 7_700)
      end
    end
    with_singleton_method(TossPayments::Client, :post_json, ->(_path, _body) { valid.merge("status" => "ABORTED") }) do
      assert_raises(RuntimeError) do
        gateway.confirm_payment!(payment_key: "test-payment", order_id: "test-order", amount: 7_700)
      end
    end
  end

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

  private

  def with_singleton_method(object, method_name, replacement)
    original = object.method(method_name)
    object.define_singleton_method(method_name, replacement)
    yield
  ensure
    object.define_singleton_method(method_name, original)
  end
end
