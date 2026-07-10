# 구현 상세

## API 클라이언트

### TossPayments::Client

**파일:** `app/services/toss_payments/client.rb`

```ruby
module TossPayments
  class Client
    BASE_URL = "https://api.tosspayments.com"

    def self.post_json(path, params)
      new.post_json(path, params)
    end

    def self.get_json(path, params = {})
      new.get_json(path, params)
    end

    def post_json(path, params)
      uri = URI.parse("#{BASE_URL}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.path, headers)
      request.body = params.to_json

      response = http.request(request)
      parse_response(response)
    end

    def get_json(path, params = {})
      uri = URI.parse("#{BASE_URL}#{path}")
      uri.query = URI.encode_www_form(params) if params.any?
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.request_uri, headers)
      response = http.request(request)
      parse_response(response)
    end

    private

    def headers
      {
        "Authorization" => auth_header,
        "Content-Type" => "application/json"
      }
    end

    def auth_header
      credentials = "#{ENV['TOSS_SECRET_KEY']}:"
      encoded = Base64.strict_encode64(credentials)
      "Basic #{encoded}"
    end

    def parse_response(response)
      body = JSON.parse(response.body)
      
      if response.code.to_i >= 400
        raise Error, body['message'] || body.to_s
      end

      body
    end
  end

  class Error < StandardError; end
end
```

---

## 모델

### User Model

**파일:** `app/models/user.rb`

```ruby
class User < ApplicationRecord
  has_one :subscription, dependent: :destroy

  def subscribed?
    subscription&.status == "done" && 
    subscription.current_period_end.present? && 
    subscription.current_period_end > Time.current
  end
end
```

### Subscription Model

**파일:** `app/models/subscription.rb`

```ruby
class Subscription < ApplicationRecord
  belongs_to :user
  
  validates :toss_customer_key, :order_id, presence: true
  validates :toss_customer_key, :order_id, uniqueness: true
  
  enum :status, { pending: "pending", done: "done", failed: "failed", canceled: "canceled" }
end
```

---

## 컨트롤러

### BillingController

**파일:** `app/controllers/billing_controller.rb`

```ruby
class BillingController < ApplicationController
  before_action :authenticate_user!

  def checkout
    @order_id = "chatdox-#{current_user.id}-#{Time.current.to_i}"
    @amount = ENV['TOSS_PRICE_AMOUNT'].to_i
  end

  def success
    payment_key = params[:paymentKey]
    order_id = params[:orderId]
    amount = params[:amount]

    response = TossPayments::Client.post_json(
      "/v1/payments/confirm",
      {
        paymentKey: payment_key,
        orderId: order_id,
        amount: amount
      }
    )

    subscription = current_user.build_subscription(
      toss_customer_key: "user-#{current_user.id}",
      toss_payment_key: response['paymentKey'],
      order_id: order_id,
      status: response['status'],
      current_period_start: Time.current,
      current_period_end: 30.days.from_now
    )

    if subscription.save
      redirect_to dashboard_path, notice: "결제가 완료되었습니다."
    else
      redirect_to root_path, alert: subscription.errors.full_messages.join(", ")
    end
  rescue TossPayments::Error => e
    redirect_to billing_checkout_path, alert: e.message
  end

  def cancel
    redirect_to root_path, notice: "결제가 취소되었습니다."
  end
end
```

### BillingAuthsController

**파일:** `app/controllers/billing_auths_controller.rb`

```ruby
class BillingAuthsController < ApplicationController
  before_action :authenticate_user!

  def create
    billing_auth_key = params[:billingAuthKey]

    response = TossPayments::Client.post_json(
      "/v1/billing/authorizations/#{billing_auth_key}",
      {}
    )

    subscription = current_user.subscription || current_user.build_subscription
    subscription.update(toss_billing_key: response['billingKey'])

    render json: { success: true, billing_key: response['billingKey'] }
  rescue TossPayments::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
```

### Webhooks::TossPaymentsController

**파일:** `app/controllers/webhooks/toss_payments_controller.rb`

```ruby
class Webhooks::TossPaymentsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    return head :unauthorized unless verify_webhook_signature

    event_type = params[:eventType]

    case event_type
    when "PAYMENT_COMPLETED"
      handle_payment_completed
    when "PAYMENT_CANCELED"
      handle_payment_canceled
    end

    head :ok
  end

  private

  def verify_webhook_signature
    secret = ENV['TOSS_WEBHOOK_SECRET']
    signature = request.headers['X-Toss-Signature']
    body = request.body.read
    request.body.rewind

    expected = OpenSSL::HMAC.hexdigest('sha256', secret, body)
    ActiveSupport::SecurityUtils.secure_compare(expected, signature)
  end

  def handle_payment_completed
    order_id = params[:data][:orderId]
    subscription = Subscription.find_by(order_id: order_id)
    subscription&.update(status: "done")
  end

  def handle_payment_canceled
    order_id = params[:data][:orderId]
    subscription = Subscription.find_by(order_id: order_id)
    subscription&.update(status: "canceled", canceled_at: Time.current)
  end
end
```

---

## 라우팅

**파일:** `config/routes.rb`

```ruby
get "billing/checkout"
get "billing/success"
get "billing/cancel"
post "billing/auths", to: "billing_auths#create"
post "webhooks/toss_payments", to: "webhooks/toss_payments#create"
```

---

## 뷰

### Checkout Page

**파일:** `app/views/billing/checkout.html.erb`

```erb
<div class="max-w-2xl mx-auto px-4 py-8">
  <h1 class="text-3xl font-bold mb-8">결제하기</h1>

  <div class="bg-white rounded-lg shadow p-6">
    <div class="mb-6">
      <p class="text-gray-600 mb-2">결제 금액</p>
      <p class="text-3xl font-bold text-blue-600">₩<%= @amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse %></p>
    </div>

    <div id="payment-method" class="mb-6"></div>
    <div id="agreement" class="mb-6"></div>
    <button id="payment-button" type="button" class="w-full bg-blue-600 text-white py-3 rounded-lg font-semibold hover:bg-blue-700">
      결제하기
    </button>
  </div>
</div>

<script src="https://js.tosspayments.com/v1/payment-widget"></script>
<script>
  const clientKey = "<%= ENV['TOSS_CLIENT_KEY'] %>";
  const orderId = "<%= @order_id %>";
  const amount = <%= @amount %>;

  const paymentWidget = PaymentWidget(clientKey, PaymentWidget.ANONYMOUS);

  paymentWidget.renderPaymentMethods(
    "#payment-method",
    { amount: amount }
  );

  paymentWidget.renderAgreement("#agreement");

  document.getElementById("payment-button").addEventListener("click", function () {
    paymentWidget.requestPayment({
      orderId: orderId,
      amount: amount,
      orderName: "ChatDox 프리미엄 구독",
      customerName: "<%= current_user.email %>",
      successUrl: window.location.origin + "/billing/success",
      failUrl: window.location.origin + "/billing"
    });
  });
</script>
```
