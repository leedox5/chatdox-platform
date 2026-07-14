# 09. 결제 (Toss Payments 또는 PortOne)

> 월 구독 결제를 구현합니다.
> `PAYMENT_PROVIDER` 설정으로 토스페이먼츠 직접 연동과 포트원 V2 연동 중 하나를 선택합니다.
> 공급자가 달라도 구독 상태와 애플리케이션의 결제 인터페이스는 동일하게 유지합니다.
> 결제 성공, 실패, 취소, 갱신, 해지까지 구독 생명주기를 다룹니다.

---

## 📋 목표

1. 토스페이먼츠 직접 연동과 포트원 V2 연동 구조 이해
2. 공급자 중립 결제/구독 데이터 모델 설계
3. 구독 시작 (월 9,900원 예시) 구현
4. 결제 성공/실패/취소 처리
5. 빌링키 기반 자동결제 구현
6. 설정으로 결제 공급자 선택
7. 공급자별 테스트 환경으로 검증

---

## 1️⃣ 결제 공급자 선택

| 모드 | 적합한 경우 | 연동 대상 |
|------|-------------|-----------|
| `toss` | 토스페이먼츠만 직접 제어하려는 경우 | Toss Payments SDK/API |
| `portone` | PG 채널 변경과 통합 운영이 필요한 경우 | PortOne Browser SDK/REST API V2 |

포트원은 PG가 아니라 여러 PG를 연결하는 결제 인프라입니다. 포트원 모드에서는 포트원 콘솔에 실제 PG 채널을 등록하고 `PORTONE_CHANNEL_KEY`로 채널을 지정합니다.

운영 중 기본 공급자를 변경해도 기존 빌링키가 자동 이전된다고 가정하면 안 됩니다. 신규 구독에는 현재 설정을 적용하고, 기존 구독의 갱신·취소·조회는 DB에 저장된 `provider`를 계속 사용합니다.

### 결제 처리의 핵심 원칙

```
클라이언트 화면만 믿으면 안 된다.
진짜 결제 상태는 선택한 공급자의 서버 승인/조회 API로 확정한다.
```

### 선택 이유

| 항목 | 토스페이먼츠 직접 연동 | 포트원 V2 |
|------|------|------|
| 한국 사업자 가입 | ✅ | ✅ (연결 PG 기준) |
| 카드 결제 | ✅ | ✅ (채널 설정 기준) |
| 자동결제(빌링) | ✅ | ✅ |
| PG 채널 변경 | 직접 재연동 | 콘솔 채널 교체 |
| 운영 편의성 | 토스 콘솔 중심 | 여러 PG 통합 운영 |

---

## 2️⃣ 결제 아키텍처

```
[사용자]
  ↓ 결제 버튼 클릭
[Rails] GET /billing/checkout
  ↓ 결제위젯 렌더링
[Toss Payments 결제위젯]
  ↓ 카드/간편결제 진행
[Toss Payments]
  ↓ successUrl 로 redirect
[Rails] POST /billing/success
  ↓ 결제 승인 API 호출
[Toss Payments 결제 승인 API]
  ↓ DB 상태 확정
[subscriptions 테이블 업데이트]

[자동결제]
  ↓ billingKey 저장
[Rails Job] 매월 청구
  ↓ 자동결제 승인 API
[Toss Payments]
```

---

## 3️⃣ 데이터 모델

> 아래 3~8절은 기존 토스페이먼츠 직접 연동 예제입니다. 두 공급자를 지원하는 신규 구현은 9절의 공급자 중립 모델과 게이트웨이를 기준으로 작성합니다.

### Subscription 테이블 예시

```ruby
# db/migrate/xxxx_create_subscriptions.rb

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
```

### 상태값 예시

| status | 의미 |
|------|------|
| `pending` | 결제 대기 |
| `active` | 구독 활성 |
| `past_due` | 결제 실패/지연 |
| `canceled` | 해지됨 |
| `expired` | 기간 만료 |

---

## 4️⃣ 환경 설정

### Step 1: 환경 변수 설정

```bash
# .env (또는 Rails credentials)
TOSS_CLIENT_KEY=test_ck_xxx
TOSS_SECRET_KEY=test_sk_xxx
TOSS_WEBHOOK_SECRET=whsec_xxx
TOSS_PRICE_AMOUNT=9900
```

### Step 2: 공통 헬퍼

```ruby
# app/services/toss_payments/client.rb
require "base64"
require "json"
require "net/http"

class TossPayments::Client
  def self.basic_auth_header
    secret_key = ENV.fetch("TOSS_SECRET_KEY")
    "Basic #{Base64.strict_encode64("#{secret_key}:")}"
  end

  def self.post_json(url, payload)
    uri = URI(url)
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = basic_auth_header
    request["Content-Type"] = "application/json"
    request.body = payload.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    JSON.parse(response.body)
  end
end
```

---

## 5️⃣ 결제위젯 연결

### 결제 시작 컨트롤러

```ruby
# app/controllers/billing_controller.rb

class BillingController < ApplicationController
  before_action :authenticate_user!

  def checkout
    @order_id = "chatdox-#{current_user.id}-#{Time.current.to_i}"
    @amount = ENV.fetch("TOSS_PRICE_AMOUNT").to_i
  end

  def success
    payment_key = params[:paymentKey]
    order_id = params[:orderId]
    amount = params[:amount].to_i

    payment = TossPayments::Client.post_json(
      "https://api.tosspayments.com/v1/payments/confirm",
      { paymentKey: payment_key, orderId: order_id, amount: amount }
    )

    subscription = current_user.subscription || current_user.build_subscription
    subscription.update!(
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

### 결제위젯 예시

```erb
<!-- app/views/billing/checkout.html.erb -->
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

## 6️⃣ 자동결제(빌링키)

### 빌링키 발급 흐름

```text
1. 구매자가 자동결제 동의 화면에서 인증
2. redirect URL로 authKey + customerKey 수신
3. 서버가 /v1/billing/authorizations/issue 호출
4. billingKey 저장
5. 다음 결제일에 billingKey로 자동 청구
```

### 자동결제 승인 서비스

```ruby
# app/services/toss_payments/billing_charge.rb

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

### 결제 수단 인증 후 billingKey 발급

```ruby
# app/controllers/billing_auths_controller.rb

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

---

## 7️⃣ 결제 상태 동기화

### 웹훅 또는 재조회 방식

결제 상태는 아래 둘 중 하나로 동기화합니다.

1. 결제 성공 콜백에서 승인 API 호출 후 바로 저장
2. 상태 변경 웹훅을 수신하면 `paymentKey`로 다시 조회해서 최신 상태 반영

```ruby
# app/controllers/webhooks/toss_payments_controller.rb

class Webhooks::TossPaymentsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def receive
    payload = JSON.parse(request.raw_post)
    return head :bad_request if payload["secret"] != ENV.fetch("TOSS_WEBHOOK_SECRET")

    payment_key = payload["paymentKey"]
    payment = TossPayments::Client.post_json(
      "https://api.tosspayments.com/v1/payments/#{payment_key}",
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

## 8️⃣ 자주 발생하는 문제

| 문제 | 원인 | 대응 |
|------|------|------|
| 결제 완료했는데 권한 미반영 | 승인 API 누락 | 승인 응답 저장 후 재조회 |
| 중복 결제 | 결제 버튼 중복 클릭 | order_id 유니크 처리 |
| 자동결제 실패 | billingKey 미저장 | 빌링키 발급 여부 확인 |
| 결제 취소 후 계속 접근 | status 동기화 누락 | status가 `active`일 때만 허용 |

### 권한 체크 예시

```ruby
def subscribed?
  subscription&.status == "active" &&
    subscription.current_period_end.present? &&
    subscription.current_period_end > Time.current
end
```

---

## 9️⃣ PortOne V2 선택 연동

### 공급자 중립 모델

토스 전용 컬럼만 사용하면 공급자 변경 시 애플리케이션 전체를 수정해야 합니다. 신규 구현은 다음 필드를 사용합니다.

```ruby
# subscriptions
t.string :provider, null: false                 # toss 또는 portone
t.string :provider_customer_id, null: false
t.string :billing_key
t.string :status, null: false, default: "pending"

# payment_transactions (결제 시도/이력)
t.references :subscription, null: false, foreign_key: true
t.string :provider, null: false
t.string :provider_payment_id, null: false
t.string :order_id, null: false
t.string :status, null: false, default: "pending"
t.integer :amount, null: false
t.string :currency, null: false, default: "KRW"
t.json :provider_payload

add_index :payment_transactions, [:provider, :provider_payment_id], unique: true
add_index :payment_transactions, :order_id, unique: true
```

기존 `toss_customer_key`, `toss_billing_key`, `toss_payment_key` 데이터가 있다면 배포 전에 중립 컬럼으로 백필하고, 충분한 검증 기간 뒤 기존 컬럼을 제거합니다. `billing_key`는 비밀 값으로 암호화하고 로그에 남기지 않습니다.

### 환경 변수

```bash
PAYMENT_PROVIDER=toss             # toss 또는 portone
PAYMENT_PRICE_AMOUNT=9900
PAYMENT_CURRENCY=KRW

# Toss 직접 연동
TOSS_CLIENT_KEY=test_ck_xxx
TOSS_SECRET_KEY=test_sk_xxx
TOSS_WEBHOOK_SECRET=whsec_xxx

# PortOne V2 연동
PORTONE_STORE_ID=store-xxx
PORTONE_CHANNEL_KEY=channel-key-xxx
PORTONE_API_SECRET=portone-api-secret
PORTONE_WEBHOOK_SECRET=portone-webhook-secret
```

API Secret과 Webhook Secret은 서버에서만 사용합니다. 브라우저에는 Store ID와 Channel Key만 전달합니다.

### 게이트웨이 선택

```ruby
# app/services/payments/gateway.rb
module Payments
  class Gateway
    def self.current
      for(ENV.fetch("PAYMENT_PROVIDER", "toss"))
    end

    def self.for(provider)
      {
        "toss" => TossGateway,
        "portone" => PortoneGateway
      }.fetch(provider).new
    end
  end
end
```

`current`는 신규 결제에만 사용합니다. 자동 갱신과 취소는 `Payments::Gateway.for(subscription.provider)`를 호출해야 설정 변경 후에도 기존 구독이 원래 공급자로 처리됩니다.

### PortOne Browser SDK V2 결제 요청

```erb
<script src="https://cdn.portone.io/v2/browser-sdk.js"></script>
<button id="portone-pay-button">월 구독 시작</button>

<script>
  document.getElementById("portone-pay-button").addEventListener("click", async () => {
    const response = await PortOne.requestPayment({
      storeId: "<%= ENV.fetch('PORTONE_STORE_ID') %>",
      channelKey: "<%= ENV.fetch('PORTONE_CHANNEL_KEY') %>",
      paymentId: "<%= @order_id %>",
      orderName: "Chatdox 월 구독",
      totalAmount: <%= @amount %>,
      currency: "KRW",
      payMethod: "CARD",
      customer: { email: "<%= current_user.email %>" }
    });

    if (response.code !== undefined) return alert(response.message);

    await fetch("<%= billing_success_path %>", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name=csrf-token]").content
      },
      body: JSON.stringify({ paymentId: response.paymentId, orderId: "<%= @order_id %>" })
    });
  });
</script>
```

### PortOne 서버 검증

포트원 V2 API는 `Authorization: PortOne {PORTONE_API_SECRET}` 헤더를 사용합니다. SDK 성공 응답만으로 구독을 활성화하지 말고 서버에서 `GET https://api.portone.io/payments/{paymentId}`를 호출하여 다음을 검증합니다.

1. 조회한 결제 ID가 서버가 발급한 주문 ID와 같은가
2. 상태가 결제 완료 상태인가
3. `amount.total`이 서버의 상품 가격과 같은가
4. 통화가 `KRW`인가

요청 파라미터의 금액을 기준으로 승인하지 않습니다. 서버 상품 가격과 공급자 조회 결과가 모두 같을 때만 `active`로 변경합니다.

### PortOne 빌링키 결제

브라우저에서 `PortOne.requestIssueBillingKey()`로 빌링키를 발급하고 즉시 서버로 전송합니다. 갱신 시 서버가 새 `paymentId`를 만든 뒤 아래 API를 호출합니다.

```text
POST https://api.portone.io/payments/{paymentId}/billing-key
Authorization: PortOne {PORTONE_API_SECRET}
Idempotency-Key: {갱신 건 고유 키}

{
  "billingKey": "...",
  "orderName": "월 구독 갱신",
  "amount": { "total": 9900 },
  "currency": "KRW",
  "customer": { "id": "customer-123" }
}
```

타임아웃이 발생하면 새 결제 ID를 만들지 말고 같은 `paymentId`로 조회하거나 동일한 멱등 키로 재시도합니다.

### PortOne 웹훅

`POST /webhooks/portone` 엔드포인트를 별도로 둡니다. 원문 body와 포트원의 공식 검증 방식으로 서명을 확인하고, 이벤트의 `paymentId`로 결제를 다시 조회한 후 상태를 반영합니다. 이벤트 ID 또는 `(provider, provider_payment_id)` 고유 인덱스로 중복 처리를 막습니다.

웹훅 payload만 믿어 상태를 변경하지 않으며, 처리 순서는 `서명 검증 → 중복 확인 → 서버 재조회 → 금액/상태 확인 → DB 트랜잭션`입니다.

---

## 🔟 공급자별 테스트 방법

### 샌드박스/테스트 키 사용

토스 모드는 토스페이먼츠 테스트 키를 사용합니다. 포트원 모드는 콘솔의 테스트 채널, Store ID, V2 API Secret을 사용합니다. 실제 운영 키와 테스트 키를 같은 환경에 섞지 않습니다.

### 확인 포인트

1. 결제위젯이 로드되는가
2. `successUrl`로 `paymentKey/orderId/amount`가 전달되는가
3. 승인 API가 성공하는가
4. subscription 상태가 `active`로 바뀌는가
5. billingKey 발급 후 자동결제가 되는가
6. 같은 콜백/웹훅이 반복되어도 한 번만 반영되는가
7. 기본 공급자를 바꿔도 기존 구독은 저장된 provider로 갱신되는가

---

## ✅ 챕터 9 체크리스트

- [ ] `PAYMENT_PROVIDER=toss|portone`으로 신규 결제 공급자를 선택할 수 있다
- [ ] 토스페이먼츠 또는 포트원 SDK로 구독 결제를 시작할 수 있다
- [ ] 승인 API로 결제 결과를 서버에서 확정한다
- [ ] `active / past_due / canceled` 상태를 DB에 반영한다
- [ ] billingKey 기반 자동결제를 구현했다
- [ ] 샌드박스 결제수단으로 성공/실패 흐름을 검증했다
- [ ] 기존 구독의 갱신은 DB에 저장된 provider를 사용한다

### 공식 참고 문서

- [PortOne V2 REST API 개요](https://developers.portone.io/api/rest-v2/overview?v=v2)
- [PortOne V2 빌링키 발급](https://developers.portone.io/opi/ko/integration/start/v2/billing/issue?v=v2)
- [PortOne V2 빌링키 결제](https://developers.portone.io/opi/ko/integration/start/v2/billing/payment?v=v2)
- [PortOne V2 웹훅](https://developers.portone.io/opi/ko/integration/webhook/readme-v2?v=v2)

---

## ➡️ 다음 챕터

10장에서는 사용자별 결제/구독 상태를 확인하고 관리할 수 있는 **대시보드**를 구현합니다.
