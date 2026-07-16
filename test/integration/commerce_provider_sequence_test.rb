require "test_helper"

class CommerceProviderSequenceTest < ActionDispatch::IntegrationTest
  ENV_KEYS = %w[
    LEEDOX_COMMERCE_ENABLED PAYMENT_PROVIDER
    PORTONE_API_SECRET PORTONE_STORE_ID PORTONE_CHANNEL_KEY
    PORTONE_WEBHOOK_SECRET
  ].freeze

  setup do
    Commerce::CatalogBootstrap.call!
    @previous_env = ENV_KEYS.to_h { |key| [ key, ENV[key] ] }
    ENV.update(
      "LEEDOX_COMMERCE_ENABLED" => "true",
      "PAYMENT_PROVIDER" => "portone",
      "PORTONE_API_SECRET" => "test-api",
      "PORTONE_STORE_ID" => "test-store",
      "PORTONE_CHANNEL_KEY" => "test-channel",
      "PORTONE_WEBHOOK_SECRET" => "test-portone-webhook"
    )
    @product = Product.find_by!(code: "chatdox")
    @product.update!(sale_enabled: true)
    @user = User.create!(name: "테스트 유저", email: "provider-sequence@example.com", password: "password123", created_at: 30.days.ago)
    post user_session_path, params: { user: { email: @user.email, password: "password123" } }
  end

  teardown do
    @previous_env.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  test "PortOne return and webhook are idempotent in both arrival orders" do
    return_first = create_order
    webhook_first = create_order

    assert_difference "License.count", 2 do
      run_portone_return(return_first)
      run_portone_webhook(return_first, status: "PAID")

      run_portone_webhook(webhook_first, status: "PAID")
      run_portone_return(webhook_first)
    end

    assert_finalized_once(return_first)
    assert_finalized_once(webhook_first)
  end

  test "provider canceled and failed webhooks create no license" do
    portone_canceled = create_order
    portone_failed = create_order

    assert_no_difference "License.count" do
      run_portone_webhook(portone_canceled, status: "CANCELLED")
      run_portone_webhook(portone_failed, status: "FAILED")
    end

    assert_equal "canceled", portone_canceled.reload.status
    assert_equal "failed", portone_failed.reload.status
    [ portone_canceled, portone_failed ].each do |order|
      assert_equal 1, PaymentTransaction.where(purchase_order: order).count
      assert_empty order.licenses
    end
  end

  test "webhook fails closed when required provider configuration is missing" do
    ENV.delete("PORTONE_API_SECRET")
    assert_no_difference [ "Order.count", "PaymentTransaction.count", "License.count" ] do
      post webhooks_portone_path,
        params: { data: { paymentId: "unknown" } }.to_json,
        headers: { "CONTENT_TYPE" => "application/json" }
      assert_response :service_unavailable
    end
  end

  test "PortOne webhook rejects a provider payment id that differs from the signed event" do
    order = create_order
    payment = {
      "id" => "different-provider-payment",
      "amount" => { "total" => order.total_amount },
      "currency" => order.currency,
      "status" => "PAID"
    }

    with_singleton_method(Portone::WebhookVerifier, :verify!, ->(**_arguments) { true }) do
      with_singleton_method(Portone::Client, :get_payment, ->(_payment_id) { payment }) do
        assert_no_difference [ "Order.count", "PaymentTransaction.count", "License.count" ] do
          post webhooks_portone_path,
            params: { data: { paymentId: order.public_id } }.to_json,
            headers: { "CONTENT_TYPE" => "application/json" }
          assert_response :bad_request
        end
      end
    end

    assert_equal "pending", order.reload.status
    assert_empty order.licenses
  end

  private

  FakePortoneGateway = Struct.new(:order) do
    def verify_payment!(payment_id:, expected_amount:, expected_currency:)
      raise "payment mismatch" unless payment_id == order.public_id
      raise "amount mismatch" unless expected_amount == order.total_amount
      raise "currency mismatch" unless expected_currency == order.currency

      {
        "id" => payment_id,
        "amount" => { "total" => expected_amount },
        "currency" => expected_currency,
        "status" => "PAID",
        "paymentMethod" => { "card" => { "number" => "sensitive-card" } },
        "customer" => { "email" => "sensitive@example.com", "phoneNumber" => "010-0000-0000" },
        "token" => "sensitive-token",
        "receiptUrl" => "https://sensitive.example/receipt",
        "unknownFutureKey" => "sensitive-unknown"
      }
    end
  end

  def create_order(provider: "portone")
    Commerce::OrderCreator.call!(
      user: @user,
      product_code: "chatdox",
      offer_code: "chatdox-1m-v1",
      requested_start_on: Time.current.in_time_zone(Commerce::PeriodCalculator::KST).to_date,
      provider: provider
    )
  end

  def run_portone_return(order)
    gateway = FakePortoneGateway.new(order)
    with_singleton_method(Payments::Gateway, :for, ->(_provider) { gateway }) do
      get billing_success_path, params: { paymentId: order.public_id }
      assert_redirected_to dashboard_path
    end
  end

  def run_portone_webhook(order, status:)
    payload = { "type" => "Transaction.Updated", "data" => { "paymentId" => order.public_id } }
    payment = {
      "id" => order.public_id,
      "amount" => { "total" => order.total_amount },
      "currency" => order.currency,
      "status" => status,
      "paymentMethod" => { "card" => { "number" => "sensitive-card" } },
      "customer" => { "email" => "sensitive@example.com", "phoneNumber" => "010-0000-0000" },
      "token" => "sensitive-token",
      "receiptUrl" => "https://sensitive.example/receipt",
      "unknownFutureKey" => "sensitive-unknown"
    }
    with_singleton_method(Portone::WebhookVerifier, :verify!, ->(**_arguments) { true }) do
      with_singleton_method(Portone::Client, :get_payment, ->(_payment_id) { payment }) do
        post webhooks_portone_path,
          params: payload.to_json,
          headers: { "CONTENT_TYPE" => "application/json" }
        assert_response :success
      end
    end
  end

  def assert_finalized_once(order)
    assert_equal "paid", order.reload.status
    assert_equal 1, PaymentTransaction.where(purchase_order: order).count
    assert_equal 1, order.licenses.count
    assert_equal [ "status" ], order.payment_transaction.reload.provider_payload.keys
  end

  def with_singleton_method(object, method_name, replacement)
    original = object.method(method_name)
    object.define_singleton_method(method_name, replacement)
    yield
  ensure
    object.define_singleton_method(method_name, original)
  end
end
