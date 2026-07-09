# 09. 결제 (Stripe)

> 월 구독 결제를 구현합니다.
> Stripe Checkout + Webhook 기반으로 안전한 결제 플로우를 만듭니다.
> 결제 성공, 실패, 취소, 갱신, 해지까지 구독 생명주기를 다룹니다.

---

## 📋 목표

1. Stripe 결제 구조 이해 (Checkout + Webhook)
2. 결제/구독 데이터 모델 설계
3. 구독 시작 (월 $9.99) 구현
4. 결제 성공/실패/취소 처리
5. 구독 갱신/해지 처리
6. 로컬 테스트 카드로 검증

---

## 1️⃣ 왜 Webhook이 중요한가?

### 결제 처리의 핵심 원칙

```
클라이언트 리다이렉트 결과만 믿으면 안 된다.
진짜 결제 상태는 Stripe 서버의 이벤트(Webhook)로 확정한다.
```

### 잘못된 구현 vs 올바른 구현

| 방식 | 설명 | 위험도 |
|------|------|------|
| 리다이렉트 URL만 사용 | success_url로 돌아오면 결제 성공으로 간주 | 높음 (조작 가능) |
| Webhook 기반 확정 | Stripe 서명 검증 + 이벤트 처리 | 낮음 (권장) |

---

## 2️⃣ 결제 아키텍처

```
[사용자]
  ↓ 결제 버튼 클릭
[Rails] POST /billing/checkout
  ↓ Checkout Session 생성
[Stripe Checkout]
  ↓ 카드 결제 진행
[Stripe]
  ↓ webhook 이벤트 전송
[Rails] POST /webhooks/stripe
  ↓ DB 상태 확정
[subscriptions 테이블 업데이트]
```

---

## 3️⃣ 데이터 모델

### Subscription 테이블 예시

```ruby
# db/migrate/xxxx_create_subscriptions.rb

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
```

### 상태값 예시

| status | 의미 |
|------|------|
| `incomplete` | 결제 미완료 |
| `active` | 구독 활성 |
| `past_due` | 결제 실패/지연 |
| `canceled` | 해지됨 |
| `unpaid` | 미납 |

---

## 4️⃣ Stripe 설정

### Step 1: 젬 설치

```bash
bundle add stripe
```

### Step 2: 환경 변수 설정

```bash
# .env (또는 Rails credentials)
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_PUBLISHABLE_KEY=pk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
STRIPE_PRICE_ID=price_xxx
```

### Step 3: 초기화 파일

```ruby
# config/initializers/stripe.rb

Stripe.api_key = ENV.fetch("STRIPE_SECRET_KEY")
```

---

## 5️⃣ Checkout Session 생성

### 결제 시작 컨트롤러

```ruby
# app/controllers/billing_controller.rb

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
    redirect_to dashboard_path, alert: "결제 세션 생성에 실패했습니다. 잠시 후 다시 시도해 주세요."
  end
end
```

---

## 6️⃣ Webhook 처리 (핵심)

### 라우트

```ruby
# config/routes.rb
post "/webhooks/stripe", to: "webhooks/stripe#receive"
```

### 컨트롤러

```ruby
# app/controllers/webhooks/stripe_controller.rb

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

    subscription_id = session.subscription
    subscription = Stripe::Subscription.retrieve(subscription_id)

    record = user.subscription || user.build_subscription
    record.update!(
      stripe_customer_id: subscription.customer,
      stripe_subscription_id: subscription.id,
      stripe_price_id: subscription.items.data.first.price.id,
      status: subscription.status,
      current_period_start: Time.at(subscription.current_period_start),
      current_period_end: Time.at(subscription.current_period_end),
      canceled_at: nil
    )
  end

  def handle_subscription_updated(subscription)
    record = Subscription.find_by(stripe_subscription_id: subscription.id)
    return unless record

    record.update!(
      status: subscription.status,
      current_period_start: Time.at(subscription.current_period_start),
      current_period_end: Time.at(subscription.current_period_end),
      cancel_at: subscription.cancel_at ? Time.at(subscription.cancel_at) : nil,
      canceled_at: subscription.canceled_at ? Time.at(subscription.canceled_at) : nil
    )
  end

  def handle_subscription_deleted(subscription)
    record = Subscription.find_by(stripe_subscription_id: subscription.id)
    return unless record

    record.update!(status: "canceled", canceled_at: Time.current)
  end

  def handle_payment_failed(invoice)
    customer_id = invoice.customer
    record = Subscription.find_by(stripe_customer_id: customer_id)
    return unless record

    record.update!(status: "past_due")
  end
end
```

---

## 7️⃣ 결제 문제(실패) 대응

### 자주 발생하는 문제

| 문제 | 원인 | 대응 |
|------|------|------|
| 결제 완료했는데 권한 미반영 | Webhook 미수신/검증 실패 | Stripe CLI로 재전송, 서버 로그 확인 |
| 중복 구독 생성 | 여러 번 결제 버튼 클릭 | user 당 단일 subscription 제약 |
| 카드 실패 후 접근 가능 | 상태 체크 누락 | `active` 상태만 유료 권한 부여 |
| 해지했는데 계속 접근 | 취소 이벤트 미처리 | `customer.subscription.deleted` 처리 |

### 권한 체크 예시

```ruby
# app/models/user.rb

def subscribed?
  subscription&.status == "active" &&
    subscription.current_period_end.present? &&
    subscription.current_period_end > Time.current
end
```

---

## 8️⃣ 로컬 테스트 방법

### Stripe CLI 설치 후 Webhook 포워딩

```bash
stripe listen --forward-to localhost:3000/webhooks/stripe
```

명령 실행 결과로 출력되는 `whsec_...` 값을 `STRIPE_WEBHOOK_SECRET`로 설정합니다.

### 테스트 카드

| 카드 번호 | 결과 |
|------|------|
| `4242 4242 4242 4242` | 성공 |
| `4000 0000 0000 9995` | 거절 (insufficient_funds) |
| `4000 0025 0000 3155` | 인증 필요 (3D Secure) |

---

## 9️⃣ 운영 체크포인트

1. Webhook 엔드포인트는 HTTPS만 허용
2. Stripe 서명 검증 필수
3. 결제 로그 + 에러 로그 분리
4. 결제 실패 사용자 알림 메일 발송
5. 중복 이벤트 대비 idempotency 고려

---

## ✅ 챕터 9 체크리스트

- [ ] Stripe Checkout으로 구독 결제를 시작할 수 있다
- [ ] Webhook으로 결제 결과를 서버에서 확정한다
- [ ] `active / past_due / canceled` 상태를 DB에 반영한다
- [ ] 구독 상태 기반 접근 제어를 적용했다
- [ ] 테스트 카드로 성공/실패 흐름을 검증했다

---

## ➡️ 다음 챕터

10장에서는 사용자별 결제/구독 상태를 확인하고 관리할 수 있는 **대시보드**를 구현합니다.
