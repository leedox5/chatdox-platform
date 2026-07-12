---
title: "09 Payment R1: 토스페이먼츠/포트원 선택형 구독 결제 구현"
description: "Platform에 Toss Payments 직접 연동 또는 PortOne V2를 선택하는 구독 결제 시스템 구현"
version: "R1"
---

# 09 Payment R1: 토스페이먼츠/포트원 선택형 구독 결제 구현

## 🎯 목표

Platform 프로젝트에 결제 시스템 구현:

1. ✅ `PAYMENT_PROVIDER=toss|portone` 공급자 선택
2. ✅ 공급자 중립 Subscription/PaymentTransaction 모델 생성
3. ✅ Toss Payments 직접 연동 또는 PortOne Browser SDK V2 결제 시작
4. ✅ 상태 동기화 (성공/실패/해지/갱신)
5. ✅ 구독 상태 기반 접근 제어 연동
6. ✅ 공급자별 테스트 환경/결제수단으로 검증

### 구현 원칙

- 신규 결제는 `PAYMENT_PROVIDER`로 선택하되 기존 구독 갱신은 `subscription.provider`를 사용한다.
- 브라우저 성공 응답만으로 구독을 활성화하지 않는다.
- 서버가 공급자 API로 상태, 주문 ID, 금액, 통화를 검증한다.
- 완료 요청과 웹훅은 멱등하게 처리한다.
- API Secret, Webhook Secret, 빌링키는 브라우저와 로그에 노출하지 않는다.

---

## 📋 필수 단계

### Step 1: 결제 공급자 환경 변수 및 SDK 준비

**환경 변수 예시 (.env 또는 credentials):**

```bash
TOSS_CLIENT_KEY=test_ck_xxx
TOSS_SECRET_KEY=test_sk_xxx
TOSS_WEBHOOK_SECRET=whsec_xxx
PAYMENT_PROVIDER=toss
PAYMENT_PRICE_AMOUNT=9900
PAYMENT_CURRENCY=KRW

# PortOne V2 (PAYMENT_PROVIDER=portone일 때)
PORTONE_STORE_ID=store-xxx
PORTONE_CHANNEL_KEY=channel-key-xxx
PORTONE_API_SECRET=portone-api-secret
PORTONE_WEBHOOK_SECRET=portone-webhook-secret
```

**참고:** 토스페이먼츠는 별도 Ruby Gem보다 `Net::HTTP` 기반 승인 API 연동이 단순합니다.

포트원은 여러 PG를 연결하는 인프라이므로 콘솔에서 실제 PG 채널을 먼저 등록한다. `PORTONE_API_SECRET`은 `Authorization: PortOne {secret}` 형식으로 서버에서만 사용한다.

---

### Step 2: Subscription 모델 생성

```bash
rails generate model Subscription user:references provider:string provider_customer_id:string billing_key:string status:string current_period_start:datetime current_period_end:datetime cancel_at:datetime canceled_at:datetime
rails generate model PaymentTransaction subscription:references provider:string provider_payment_id:string order_id:string status:string amount:integer currency:string provider_payload:json
```

**파일: `db/migrate/xxxxxx_create_subscriptions.rb`**

생성된 마이그레이션에서 제약을 아래처럼 보강:

```ruby
class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :provider_customer_id, null: false
      t.string :billing_key
      t.string :status, null: false, default: "pending"
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.datetime :cancel_at
      t.datetime :canceled_at

      t.timestamps
    end

    add_index :subscriptions, [:provider, :provider_customer_id], unique: true
  end
end
```

```bash
rails db:migrate
```

---

### Step 3: 모델 연관관계 추가

**파일: `app/models/user.rb`**

```ruby
class User < ApplicationRecord
  has_one :subscription, dependent: :destroy

  def subscribed?
    subscription&.status == "active" &&
      subscription.current_period_end.present? &&
      subscription.current_period_end > Time.current
  end
end
```

**파일: `app/models/subscription.rb`**

```ruby
class Subscription < ApplicationRecord
  belongs_to :user

  validates :provider, :provider_customer_id, :status, presence: true
end
```

---

### Step 4: 결제 라우트 + BillingController

**파일: `config/routes.rb`**

```ruby
Rails.application.routes.draw do
  # ... existing routes

  get "/billing/checkout", to: "billing#checkout", as: :billing_checkout
  post "/billing/success", to: "billing#success", as: :billing_success
  get "/billing/cancel", to: "billing#cancel", as: :billing_cancel

  post "/billing/auths", to: "billing_auths#create", as: :billing_auths
  post "/webhooks/toss_payments", to: "webhooks/toss_payments#receive"
  post "/webhooks/portone", to: "webhooks/portone#receive"
end
```

**파일: `app/controllers/billing_controller.rb`** (새로 생성)

```ruby
class BillingController < ApplicationController
  before_action :authenticate_user!

  def checkout
    @order_id = "chatdox-#{current_user.id}-#{Time.current.to_i}"
    @amount = ENV.fetch("PAYMENT_PRICE_AMOUNT").to_i
  end

  def success
    expected_amount = ENV.fetch("PAYMENT_PRICE_AMOUNT").to_i
    payment = TossPayments::Client.post_json(
      "https://api.tosspayments.com/v1/payments/confirm",
      {
        paymentKey: params[:paymentKey],
        orderId: params[:orderId],
        amount: expected_amount
      }
    )

    raise "amount mismatch" unless payment["totalAmount"] == expected_amount
    raise "payment is not done" unless payment["status"] == "DONE"

    ApplicationRecord.transaction do
      record = current_user.subscription || current_user.build_subscription
      record.update!(
        provider: "toss",
        provider_customer_id: current_user.id.to_s,
        status: "active",
        current_period_start: Time.current,
        current_period_end: 1.month.from_now
      )
      record.payment_transactions.create!(
        provider: "toss",
        provider_payment_id: payment.fetch("paymentKey"),
        order_id: payment.fetch("orderId"),
        status: "active",
        amount: payment.fetch("totalAmount"),
        currency: payment.fetch("currency", "KRW"),
        provider_payload: payment
      )
    end

    redirect_to dashboard_path, notice: "결제가 완료되었습니다."
  rescue StandardError => e
    Rails.logger.error("Toss Payments confirm error: #{e.message}")
    redirect_to dashboard_path, alert: "결제 승인에 실패했습니다."
  end

  def cancel
    redirect_to dashboard_path, alert: "결제가 취소되었습니다."
  end
end
```

---

### Step 5: 결제위젯 UI

**파일: `app/views/billing/checkout.html.erb`**

```erb
<script src="https://js.tosspayments.com/v2/standard"></script>

<button id="pay-button" class="px-5 py-3 rounded-lg bg-blue-600 text-white font-semibold">
  월 구독 시작
</button>

<script>
  const tossPayments = TossPayments("<%= ENV.fetch('TOSS_CLIENT_KEY') %>");

  document.getElementById("pay-button").addEventListener("click", async () => {
    await tossPayments.requestPayment("카드", {
      amount: <%= @amount %>,
      orderId: "<%= @order_id %>",
      orderName: "Chatdox 월 구독",
      successUrl: "<%= billing_success_url %>",
      failUrl: "<%= billing_cancel_url %>",
      customerKey: "<%= current_user.id %>",
      customerEmail: "<%= current_user.email %>",
      customerName: "<%= current_user.email %>"
    });
  });
</script>
```

---

### Step 6: 자동결제(빌링키) 발급

**파일: `app/controllers/billing_auths_controller.rb`**

```ruby
class BillingAuthsController < ApplicationController
  before_action :authenticate_user!

  def create
    payment = TossPayments::Client.post_json(
      "https://api.tosspayments.com/v1/billing/authorizations/issue",
      { authKey: params[:authKey], customerKey: current_user.id.to_s }
    )

    current_user.subscription.update!(
      provider: "toss",
      provider_customer_id: payment["customerKey"],
      billing_key: payment["billingKey"],
      status: "active"
    )

    redirect_to dashboard_path, notice: "자동결제가 활성화되었습니다."
  end
end
```

**파일: `app/services/toss_payments/billing_charge.rb`**

```ruby
class TossPayments::BillingCharge
  def self.charge!(billing_key:, customer_key:, amount:, order_name:)
    TossPayments::Client.post_json(
      "https://api.tosspayments.com/v1/billing/#{billing_key}",
      {
        customerKey: customer_key,
        amount: amount,
        orderId: "renewal-#{Time.current.to_i}",
        orderName: order_name
      }
    )
  end
end
```

---

### Step 7: 상태 동기화 웹훅

**파일: `app/controllers/webhooks/toss_payments_controller.rb`**

```ruby
class Webhooks::TossPaymentsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def receive
    payload = JSON.parse(request.raw_post)
    return head :bad_request if payload["secret"] != ENV.fetch("TOSS_WEBHOOK_SECRET")

    payment = TossPayments::Client.post_json(
      "https://api.tosspayments.com/v1/payments/#{payload['paymentKey']}",
      {}
    )

    transaction = PaymentTransaction.find_by(
      provider: "toss", provider_payment_id: payment["paymentKey"]
    )
    return head :ok unless transaction

    transaction.update!(status: payment["status"].downcase)
    transaction.subscription.update!(status: payment["status"].downcase)
    head :ok
  rescue StandardError => e
    Rails.logger.error("Toss webhook error: #{e.message}")
    head :internal_server_error
  end
end
```

---

## PortOne V2 대체 구현 요구사항

`PAYMENT_PROVIDER=portone`이면 토스 전용 컨트롤러를 복제하지 말고 `Payments::Gateway` 인터페이스 아래 `Payments::PortoneGateway`를 구현한다. 신규 데이터 모델은 다음 중립 필드를 사용한다.

```text
subscriptions: provider, provider_customer_id, billing_key, status, period fields
payment_transactions: provider, provider_payment_id, order_id, status, amount, currency, provider_payload
```

`(provider, provider_payment_id)`와 `order_id`에는 unique index를 둔다. 기존 `toss_*` 데이터가 있으면 중립 컬럼으로 백필하는 데이터 마이그레이션을 작성한다.

필수 PortOne 흐름:

1. Browser SDK V2의 `PortOne.requestPayment()`에 `storeId`, `channelKey`, 고객사가 채번한 `paymentId`, `totalAmount`, `currency`, `payMethod`를 전달한다.
2. SDK 성공 후 서버가 `GET https://api.portone.io/payments/{paymentId}`로 결제를 재조회한다.
3. 서버 상품 가격과 `amount.total`, 통화, 결제 상태가 일치할 때만 구독을 활성화한다.
4. `PortOne.requestIssueBillingKey()`로 빌링키를 발급하고 서버에만 저장한다.
5. 갱신은 `POST /payments/{paymentId}/billing-key`와 고유한 `Idempotency-Key`로 요청한다.
6. `POST /webhooks/portone`에서 공식 방식으로 웹훅을 검증한 뒤 paymentId를 재조회한다.

공급자 선택기 예시:

```ruby
module Payments
  class Gateway
    def self.current = for(ENV.fetch("PAYMENT_PROVIDER", "toss"))

    def self.for(provider)
      { "toss" => TossGateway, "portone" => PortoneGateway }.fetch(provider).new
    end
  end
end
```

갱신 작업에서는 `Gateway.current`가 아니라 `Gateway.for(subscription.provider)`를 사용한다.

공식 참고 문서:

- https://developers.portone.io/api/rest-v2/overview?v=v2
- https://developers.portone.io/opi/ko/integration/start/v2/billing/issue?v=v2
- https://developers.portone.io/opi/ko/integration/start/v2/billing/payment?v=v2
- https://developers.portone.io/opi/ko/integration/webhook/readme-v2?v=v2

---

## 🧯 트러블슈팅

| 문제 | 원인 | 해결 |
|------|------|------|
| 결제 성공인데 권한 미반영 | 승인 API 누락 | 승인 응답 저장 후 재조회 |
| 중복 결제 | 버튼 중복 클릭 | `order_id` 유니크 처리 |
| 자동결제 실패 | billingKey 미저장 | 빌링키 발급 여부 확인 |
| 취소했는데 계속 접근 | 상태 동기화 누락 | `active`만 유료 권한 부여 |

---

## ✅ 구현 체크리스트

### 파일 생성/수정
- [ ] `app/services/toss_payments/client.rb`
- [ ] `app/services/toss_payments/billing_charge.rb`
- [ ] `app/services/payments/gateway.rb`
- [ ] `app/services/payments/toss_gateway.rb`
- [ ] `app/services/payments/portone_gateway.rb`
- [ ] `app/services/portone/client.rb`
- [ ] `app/controllers/billing_controller.rb`
- [ ] `app/controllers/billing_auths_controller.rb`
- [ ] `app/controllers/webhooks/toss_payments_controller.rb`
- [ ] `app/controllers/webhooks/portone_controller.rb`
- [ ] `app/views/billing/checkout.html.erb`
- [ ] `config/routes.rb` 결제/웹훅 라우트 추가
- [ ] `Subscription` 모델/마이그레이션

### 검증
- [ ] 결제위젯으로 결제 시작 가능
- [ ] 승인 API 성공 시 subscription 활성화
- [ ] billingKey 발급 후 자동결제 가능
- [ ] 웹훅 수신 시 상태 동기화
- [ ] 샌드박스 환경에서 성공/실패 확인
- [ ] `PAYMENT_PROVIDER` 변경 시 신규 결제 공급자 전환 확인
- [ ] 기존 구독이 저장된 provider로 갱신되는지 확인
- [ ] 콜백/웹훅 중복 수신 및 금액 위변조 검증

---

## 📌 다음 단계 (Chapter 10 연계)

- 대시보드에서 현재 플랜/만료일/결제 상태 표시
- 결제 이력 목록 및 해지 버튼 제공
- `past_due` 사용자 안내 배너/이메일 추가

---

**마지막 업데이트:** 2026-07-10 (PortOne V2 선택 연동 추가)
