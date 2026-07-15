require "test_helper"

class CommerceCheckoutTest < ActionDispatch::IntegrationTest
  PAYMENT_ENV_KEYS = %w[
    LEEDOX_COMMERCE_ENABLED PAYMENT_PROVIDER TOSS_CLIENT_KEY TOSS_SECRET_KEY
    TOSS_WEBHOOK_SECRET PORTONE_API_SECRET PORTONE_STORE_ID PORTONE_CHANNEL_KEY
    PORTONE_WEBHOOK_SECRET
  ].freeze

  setup do
    Commerce::CatalogBootstrap.call!
    @previous_payment_env = PAYMENT_ENV_KEYS.to_h { |key| [ key, ENV[key] ] }
    @product = Product.find_by!(code: "chatdox")
    @user = User.create!(email: "checkout-r2b@example.com", password: "password123", created_at: 30.days.ago)
  end

  teardown do
    @previous_payment_env.each { |key, value| restore_env(key, value) }
  end

  test "default configuration preserves the R2A inactive checkout and blocks direct order POST" do
    ENV["LEEDOX_COMMERCE_ENABLED"] = "false"
    @product.update!(sale_enabled: true)
    sign_in

    assert_no_difference [ "Order.count", "OrderItem.count", "PaymentTransaction.count", "Subscription.count" ] do
      get billing_checkout_path
    end
    assert_response :success
    assert_match(/신규 결제를 준비하고 있습니다/, response.body)
    assert_select "script[src*='tosspayments']", count: 0
    assert_select "script[src*='portone']", count: 0

    assert_no_difference [ "Order.count", "PaymentTransaction.count" ] do
      post billing_orders_path, params: {
        order: { product_code: "chatdox", offer_code: "chatdox-1m-v1", requested_start_on: Date.current }
      }
    end
    assert_redirected_to billing_checkout_path
  end

  test "enabled checkout uses server offer despite a client amount parameter" do
    enable_chatdox_sales
    sign_in
    today = Time.current.in_time_zone(Commerce::PeriodCalculator::KST).to_date

    get billing_checkout_path
    assert_response :success
    assert_select "input[name='order[offer_code]']", count: 4
    assert_select "input[name='order[requested_start_on]'][min=?][max=?]", today.iso8601, (today + 7.days).iso8601
    assert_match(/7,700원/, response.body)

    assert_difference [ "Order.count", "OrderItem.count", "PaymentTransaction.count" ], 1 do
      assert_no_difference "Subscription.count" do
        post billing_orders_path, params: {
          order: {
            product_code: "chatdox",
            offer_code: "chatdox-1m-v1",
            requested_start_on: today,
            total_amount: 1,
            duration_months: 99,
            currency: "USD"
          }
        }
      end
    end

    order = Order.order(:created_at).last
    assert_redirected_to billing_order_path(order.public_id)
    assert_equal [ 1, 7_000, 700, 7_700, "KRW" ], [
      order.order_items.first.duration_months,
      order.supply_amount,
      order.vat_amount,
      order.total_amount,
      order.currency
    ]

    follow_redirect!
    assert_response :success
    assert_match(/7,700원/, response.body)
    assert_match(/자동 갱신되지 않는 일회성 선불 결제/, response.body)
  end

  test "enabled sale gates with missing PG configuration fail closed without exposing values" do
    ENV["LEEDOX_COMMERCE_ENABLED"] = "true"
    @product.update!(sale_enabled: true)
    (PAYMENT_ENV_KEYS - %w[LEEDOX_COMMERCE_ENABLED]).each { |key| ENV.delete(key) }
    sign_in

    assert_no_difference [ "Order.count", "PaymentTransaction.count", "Subscription.count" ] do
      get billing_checkout_path
      assert_response :success
      assert_match(/신규 결제를 준비하고 있습니다/, response.body)
      assert_select "script[src*='tosspayments']", count: 0
      assert_select "script[src*='portone']", count: 0

      post billing_orders_path, params: {
        order: { product_code: "chatdox", offer_code: "chatdox-1m-v1", requested_start_on: Date.current }
      }
      assert_redirected_to billing_checkout_path
    end
  end

  test "existing Chatdox period is displayed as a fixed extension date" do
    enable_chatdox_sales
    sign_in
    today = Time.current.in_time_zone(Commerce::PeriodCalculator::KST).to_date
    last_on = today + 20.days
    License.create!(
      user: @user,
      product: @product,
      source: "paid",
      status: "active",
      starts_on: today,
      last_usable_on: last_on,
      access_ends_at: Commerce::PeriodCalculator::KST.local(*(last_on + 1.day).then { |date| [ date.year, date.month, date.day ] })
    )

    get billing_checkout_path

    assert_response :success
    assert_match(/자동으로 연장됩니다/, response.body)
    assert_select "input[type='hidden'][name='order[requested_start_on]'][value=?]", (last_on + 1.day).iso8601
    assert_select "input[type='date'][name='order[requested_start_on]']", count: 0
  end

  test "Claudox has no purchase path even when global commerce is enabled" do
    ENV["LEEDOX_COMMERCE_ENABLED"] = "true"
    Product.find_by!(code: "claudox").update!(sale_enabled: false)
    sign_in

    assert_no_difference "Order.count" do
      post billing_orders_path, params: {
        order: { product_code: "claudox", offer_code: "chatdox-1m-v1", requested_start_on: Date.current }
      }
    end
    assert_redirected_to billing_checkout_path
  end

  test "success callback resend finalizes one order and one license" do
    enable_chatdox_sales
    sign_in
    order = create_order
    gateway = FakeTossGateway.new(order)

    with_singleton_method(Payments::Gateway, :for, ->(_provider) { gateway }) do
      2.times do
        get billing_success_path, params: {
          orderId: order.public_id,
          paymentKey: "callback-payment",
          amount: 1
        }
        assert_redirected_to dashboard_path
      end
    end

    assert_equal "paid", order.reload.status
    assert_equal 1, order.licenses.count
    assert_equal 1, PaymentTransaction.where(purchase_order: order).count
    assert_nil @user.reload.subscription
  end

  test "Toss webhook resend finalizes the existing pending order only once" do
    enable_chatdox_sales
    order = create_order
    ENV["TOSS_WEBHOOK_SECRET"] = "test-webhook-secret"
    payment = {
      "paymentKey" => "webhook-payment",
      "orderId" => order.public_id,
      "totalAmount" => order.total_amount,
      "currency" => order.currency,
      "status" => "DONE"
    }

    with_singleton_method(TossPayments::Client, :get_json, ->(_path) { payment }) do
      assert_difference "License.count", 1 do
        2.times do
          post webhooks_toss_payments_path,
            params: { secret: "test-webhook-secret", paymentKey: "webhook-payment" }.to_json,
            headers: { "CONTENT_TYPE" => "application/json" }
          assert_response :success
        end
      end
    end

    assert_equal 1, order.reload.licenses.count
    assert_nil @user.reload.subscription
  end

  test "PortOne webhook resend keeps one order transaction and license without subscription" do
    enable_chatdox_sales
    order = create_order(provider: "portone")
    payload = {
      "type" => "Transaction.Paid",
      "data" => { "paymentId" => order.public_id }
    }
    payment = {
      "id" => order.public_id,
      "amount" => { "total" => order.total_amount },
      "currency" => order.currency,
      "status" => "PAID"
    }

    verifier = ->(**_arguments) { true }
    payment_lookup = ->(_payment_id) { payment }
    with_singleton_method(Portone::WebhookVerifier, :verify!, verifier) do
      with_singleton_method(Portone::Client, :get_payment, payment_lookup) do
        assert_no_difference [ "Order.count", "PaymentTransaction.count", "Subscription.count" ] do
          assert_difference "License.count", 1 do
            2.times do
              post webhooks_portone_path,
                params: payload.to_json,
                headers: { "CONTENT_TYPE" => "application/json" }
              assert_response :success
            end
          end
        end
      end
    end

    assert_equal 1, Order.where(id: order.id).count
    assert_equal 1, PaymentTransaction.where(purchase_order: order).count
    assert_equal 1, order.reload.licenses.count
    assert_nil @user.reload.subscription
  end

  test "Dashboard and My Page show product license and order summaries" do
    enable_chatdox_sales
    sign_in
    order = create_order
    Commerce::OrderFinalizer.call!(order: order, payment: payment_for(order))

    get dashboard_path
    assert_response :success
    assert_match(/상품별 라이선스/, response.body)
    assert_match(/Chatdox/, response.body)
    assert_match(/결제 완료/, response.body)

    get mypage_path
    assert_response :success
    assert_match(/상품별 라이선스/, response.body)
    assert_match(/Chatdox/, response.body)
  end

  private

  FakeTossGateway = Struct.new(:order) do
    def confirm_payment!(payment_key:, order_id:, amount:)
      raise "unexpected order" unless order_id == order.public_id
      raise "unexpected server amount" unless amount == order.total_amount

      {
        "paymentKey" => payment_key,
        "orderId" => order_id,
        "totalAmount" => amount,
        "currency" => order.currency,
        "status" => "DONE"
      }
    end
  end

  def enable_chatdox_sales
    ENV["LEEDOX_COMMERCE_ENABLED"] = "true"
    ENV["PAYMENT_PROVIDER"] = "toss"
    ENV["TOSS_CLIENT_KEY"] = "test-client-key"
    ENV["TOSS_SECRET_KEY"] = "test-secret-key"
    ENV["TOSS_WEBHOOK_SECRET"] = "test-webhook-secret"
    ENV["PORTONE_API_SECRET"] = "test-api-secret"
    ENV["PORTONE_STORE_ID"] = "test-store-id"
    ENV["PORTONE_CHANNEL_KEY"] = "test-channel-key"
    ENV["PORTONE_WEBHOOK_SECRET"] = "test-portone-webhook-secret"
    @product.update!(sale_enabled: true)
  end

  def sign_in
    post user_session_path, params: { user: { email: @user.email, password: "password123" } }
  end

  def create_order(provider: "toss")
    Commerce::OrderCreator.call!(
      user: @user,
      product_code: "chatdox",
      offer_code: "chatdox-1m-v1",
      requested_start_on: Time.current.in_time_zone(Commerce::PeriodCalculator::KST).to_date,
      provider: provider
    )
  end

  def payment_for(order)
    {
      provider: "toss",
      provider_payment_id: "dashboard-payment",
      order_id: order.public_id,
      amount: order.total_amount,
      currency: order.currency,
      provider_payload: {}
    }
  end

  def restore_env(key, value)
    value.nil? ? ENV.delete(key) : ENV[key] = value
  end

  def with_singleton_method(object, method_name, replacement)
    original = object.method(method_name)
    object.define_singleton_method(method_name, replacement)
    yield
  ensure
    object.define_singleton_method(method_name, original)
  end
end
