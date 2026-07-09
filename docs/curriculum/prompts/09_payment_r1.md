---
title: "09 Payment R1: 토스페이먼츠 구독 결제 구현"
description: "Platform에 Toss Payments 결제위젯 + 승인 API + 자동결제 시스템 구현"
version: "R1"
---

# 09 Payment R1: 토스페이먼츠 구독 결제 구현

## 🎯 목표

Platform 프로젝트에 결제 시스템 구현:

1. ✅ 토스페이먼츠 환경 변수/위젯 설정
2. ✅ Subscription 모델/마이그레이션 생성
3. ✅ 결제 시작 (결제위젯 + 승인 API)
4. ✅ 상태 동기화 (성공/실패/해지/갱신)
5. ✅ 구독 상태 기반 접근 제어 연동
6. ✅ 샌드박스/테스트 결제수단으로 검증

---

## 📋 필수 단계

### Step 1: 토스페이먼츠 환경 변수 및 SDK 준비

**환경 변수 예시 (.env 또는 credentials):**

```bash
TOSS_CLIENT_KEY=test_ck_xxx
TOSS_SECRET_KEY=test_sk_xxx
TOSS_WEBHOOK_SECRET=whsec_xxx
TOSS_PRICE_AMOUNT=9900
```

**참고:** 토스페이먼츠는 별도 Ruby Gem보다 `Net::HTTP` 기반 승인 API 연동이 단순합니다.

---

### Step 2: Subscription 모델 생성

```bash
rails generate model Subscription user:references toss_customer_key:string toss_billing_key:string toss_payment_key:string order_id:string status:string current_period_start:datetime current_period_end:datetime cancel_at:datetime canceled_at:datetime
```

**파일: `db/migrate/xxxxxx_create_subscriptions.rb`**

생성된 마이그레이션에서 제약을 아래처럼 보강:

```ruby
class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :toss_customer_key, null: false
      t.string :toss_billing_key
      t.string :toss_payment_key
      t.string :order_id, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.datetime :cancel_at
      t.datetime :canceled_at

      t.timestamps
    end

    add_index :subscriptions, :toss_customer_key, unique: true
    add_index :subscriptions, :order_id, unique: true
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

  validates :toss_customer_key, :order_id, :status, presence: true
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
end
```

**파일: `app/controllers/billing_controller.rb`** (새로 생성)

```ruby
class BillingController < ApplicationController
  before_action :authenticate_user!

  def checkout
    @order_id = "chatdox-#{current_user.id}-#{Time.current.to_i}"
    @amount = ENV.fetch("TOSS_PRICE_AMOUNT").to_i
  end

  def success
    payment = TossPayments::Client.post_json(
      "https://api.tosspayments.com/v1/payments/confirm",
      {
        paymentKey: params[:paymentKey],
        orderId: params[:orderId],
        amount: params[:amount].to_i
      }
    )

    record = current_user.subscription || current_user.build_subscription
    record.update!(
      toss_customer_key: current_user.id.to_s,
      toss_payment_key: payment["paymentKey"],
      order_id: payment["orderId"],
      status: payment["status"].downcase,
      current_period_start: Time.current,
      current_period_end: 1.month.from_now
    )

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
      toss_customer_key: payment["customerKey"],
      toss_billing_key: payment["billingKey"],
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

    subscription = Subscription.find_by(toss_payment_key: payment["paymentKey"])
    return head :ok unless subscription

    subscription.update!(status: payment["status"].downcase)
    head :ok
  rescue StandardError => e
    Rails.logger.error("Toss webhook error: #{e.message}")
    head :internal_server_error
  end
end
```

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
- [ ] `app/controllers/billing_controller.rb`
- [ ] `app/controllers/billing_auths_controller.rb`
- [ ] `app/controllers/webhooks/toss_payments_controller.rb`
- [ ] `app/views/billing/checkout.html.erb`
- [ ] `config/routes.rb` 결제/웹훅 라우트 추가
- [ ] `Subscription` 모델/마이그레이션

### 검증
- [ ] 결제위젯으로 결제 시작 가능
- [ ] 승인 API 성공 시 subscription 활성화
- [ ] billingKey 발급 후 자동결제 가능
- [ ] 웹훅 수신 시 상태 동기화
- [ ] 샌드박스 환경에서 성공/실패 확인

---

## 📌 다음 단계 (Chapter 10 연계)

- 대시보드에서 현재 플랜/만료일/결제 상태 표시
- 결제 이력 목록 및 해지 버튼 제공
- `past_due` 사용자 안내 배너/이메일 추가

---

**마지막 업데이트:** 2026-07-10
