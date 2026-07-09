---
title: "09 Payment R1: Stripe 구독 결제 구현"
description: "Platform에 Stripe Checkout + Webhook 기반 결제/구독 시스템 구현"
version: "R1"
---

# 09 Payment R1: Stripe 구독 결제 구현

## 🎯 목표

Platform 프로젝트에 결제 시스템 구현:

1. ✅ Stripe 젬/환경 변수 설정
2. ✅ Subscription 모델/마이그레이션 생성
3. ✅ 결제 시작 (Checkout Session)
4. ✅ Webhook 이벤트 처리 (성공/실패/해지/갱신)
5. ✅ 구독 상태 기반 접근 제어 연동
6. ✅ 로컬 테스트 카드로 검증

---

## 📋 필수 단계

### Step 1: Stripe 젬 설치 및 설정

```bash
# Platform 폴더에서
cd ~/chatdox-platform

# Stripe SDK 설치
bundle add stripe
```

**파일: `config/initializers/stripe.rb`** (새로 생성)

```ruby
# config/initializers/stripe.rb
Stripe.api_key = ENV.fetch("STRIPE_SECRET_KEY")
```

**환경 변수 예시 (.env 또는 credentials):**

```bash
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_PUBLISHABLE_KEY=pk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
STRIPE_PRICE_ID=price_xxx
```

---

### Step 2: Subscription 모델 생성

```bash
rails generate model Subscription user:references stripe_customer_id:string stripe_subscription_id:string stripe_price_id:string status:string current_period_start:datetime current_period_end:datetime cancel_at:datetime canceled_at:datetime
```

**파일: `db/migrate/xxxxxx_create_subscriptions.rb`**

생성된 마이그레이션에서 `null`/`index` 제약을 아래처럼 보강:

```ruby
class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :stripe_customer_id, null: false
      t.string :stripe_subscription_id, null: false
      t.string :stripe_price_id, null: false
      t.string :status, null: false, default: "incomplete"
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.datetime :cancel_at
      t.datetime :canceled_at

      t.timestamps
    end

    add_index :subscriptions, :stripe_customer_id, unique: true
    add_index :subscriptions, :stripe_subscription_id, unique: true
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

  validates :stripe_customer_id, :stripe_subscription_id, :stripe_price_id, :status, presence: true
end
```

---

### Step 4: 결제 라우트 + BillingController

**파일: `config/routes.rb`**

```ruby
Rails.application.routes.draw do
  # ... existing routes

  post "/billing/checkout", to: "billing#checkout", as: :billing_checkout
  get "/billing/success", to: "billing#success", as: :billing_success
  get "/billing/cancel", to: "billing#cancel", as: :billing_cancel

  post "/webhooks/stripe", to: "webhooks/stripe#receive"
end
```

**파일: `app/controllers/billing_controller.rb`** (새로 생성)

```ruby
class BillingController < ApplicationController
  before_action :authenticate_user!

  def checkout
    session = Stripe::Checkout::Session.create(
      mode: "subscription",
      customer_email: current_user.email,
      line_items: [{ price: ENV.fetch("STRIPE_PRICE_ID"), quantity: 1 }],
      success_url: billing_success_url + "?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: billing_cancel_url,
      metadata: { user_id: current_user.id }
    )

    redirect_to session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    Rails.logger.error("Stripe checkout error: #{e.message}")
    redirect_to root_path, alert: "결제 세션 생성에 실패했습니다. 잠시 후 다시 시도해 주세요."
  end

  def success
    redirect_to root_path, notice: "결제가 처리 중입니다. 잠시 후 구독 상태가 반영됩니다."
  end

  def cancel
    redirect_to root_path, alert: "결제가 취소되었습니다."
  end
end
```

---

### Step 5: Stripe Webhook 구현 (핵심)

**파일: `app/controllers/webhooks/stripe_controller.rb`** (새로 생성)

```ruby
class Webhooks::StripeController < ApplicationController
  skip_before_action :verify_authenticity_token

  def receive
    payload = request.raw_post
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    secret = ENV.fetch("STRIPE_WEBHOOK_SECRET")

    event = Stripe::Webhook.construct_event(payload, sig_header, secret)

    case event.type
    when "checkout.session.completed"
      handle_checkout_completed(event.data.object)
    when "customer.subscription.updated"
      handle_subscription_updated(event.data.object)
    when "customer.subscription.deleted"
      handle_subscription_deleted(event.data.object)
    when "invoice.payment_failed"
      handle_payment_failed(event.data.object)
    end

    head :ok
  rescue JSON::ParserError, Stripe::SignatureVerificationError => e
    Rails.logger.warn("Webhook signature/parse error: #{e.message}")
    head :bad_request
  rescue StandardError => e
    Rails.logger.error("Webhook processing error: #{e.message}")
    head :internal_server_error
  end

  private

  def handle_checkout_completed(session)
    user = User.find_by(id: session.metadata.user_id)
    return unless user

    stripe_sub = Stripe::Subscription.retrieve(session.subscription)

    record = user.subscription || user.build_subscription
    record.update!(
      stripe_customer_id: stripe_sub.customer,
      stripe_subscription_id: stripe_sub.id,
      stripe_price_id: stripe_sub.items.data.first.price.id,
      status: stripe_sub.status,
      current_period_start: Time.at(stripe_sub.current_period_start),
      current_period_end: Time.at(stripe_sub.current_period_end),
      cancel_at: nil,
      canceled_at: nil
    )
  end

  def handle_subscription_updated(stripe_sub)
    record = Subscription.find_by(stripe_subscription_id: stripe_sub.id)
    return unless record

    record.update!(
      status: stripe_sub.status,
      current_period_start: Time.at(stripe_sub.current_period_start),
      current_period_end: Time.at(stripe_sub.current_period_end),
      cancel_at: stripe_sub.cancel_at ? Time.at(stripe_sub.cancel_at) : nil,
      canceled_at: stripe_sub.canceled_at ? Time.at(stripe_sub.canceled_at) : nil
    )
  end

  def handle_subscription_deleted(stripe_sub)
    record = Subscription.find_by(stripe_subscription_id: stripe_sub.id)
    return unless record

    record.update!(status: "canceled", canceled_at: Time.current)
  end

  def handle_payment_failed(invoice)
    record = Subscription.find_by(stripe_customer_id: invoice.customer)
    return unless record

    record.update!(status: "past_due")
  end
end
```

---

### Step 6: 결제 버튼 연결 (예: Pricing 또는 Dashboard)

예시 버튼:

```erb
<%= button_to "월 $9.99 구독 시작",
  billing_checkout_path,
  method: :post,
  class: "px-5 py-3 rounded-lg bg-blue-600 hover:bg-blue-700 text-white font-semibold" %>
```

---

### Step 7: 로컬 테스트

#### 1) Webhook 포워딩

```bash
stripe listen --forward-to localhost:3000/webhooks/stripe
```

출력된 `whsec_...` 값을 `STRIPE_WEBHOOK_SECRET`에 적용.

#### 2) 결제 테스트 카드

- 성공: `4242 4242 4242 4242`
- 실패: `4000 0000 0000 9995`
- 3DS: `4000 0025 0000 3155`

#### 3) 확인 포인트

- `checkout.session.completed` 수신 시 `subscriptions.status = active`
- 결제 실패 시 `past_due` 반영
- 구독 해지 시 `canceled` 반영

---

## 🧯 트러블슈팅

| 문제 | 원인 | 해결 |
|------|------|------|
| 결제 성공인데 권한 미반영 | Webhook 미수신 | `stripe listen` 연결 상태 확인, 이벤트 재전송 |
| 중복 구독 생성 | 버튼 중복 클릭 | user 1:1 subscription 유지, 서버에서 upsert 처리 |
| 서명 검증 실패 | webhook secret 불일치 | `whsec_...` 재설정 |
| 상태가 계속 active | delete/update 이벤트 미처리 | `customer.subscription.deleted/updated` 처리 확인 |

---

## ✅ 구현 체크리스트

### 파일 생성/수정
- [ ] `config/initializers/stripe.rb`
- [ ] `db/migrate/*_create_subscriptions.rb`
- [ ] `app/models/subscription.rb`
- [ ] `app/models/user.rb` (`has_one`, `subscribed?`)
- [ ] `config/routes.rb` (checkout/success/cancel/webhook)
- [ ] `app/controllers/billing_controller.rb`
- [ ] `app/controllers/webhooks/stripe_controller.rb`
- [ ] 결제 버튼 뷰 1곳 이상 연결

### 검증
- [ ] 결제 성공 시 subscription 생성/갱신
- [ ] 결제 실패 시 `past_due` 반영
- [ ] 해지 시 `canceled` 반영
- [ ] 권한 체크에서 `subscribed?` 정상 동작

---

## 📌 다음 단계 (Chapter 10 연계)

- 대시보드에서 현재 플랜/만료일/결제 상태 표시
- 결제 이력 목록 및 해지 버튼 제공
- `past_due` 사용자 안내 배너/이메일 추가

---

**마지막 업데이트:** 2026-07-09
