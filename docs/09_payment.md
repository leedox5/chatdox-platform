# 09. 결제 (Toss Payments)

> 월 구독 결제를 구현합니다.
> 토스페이먼츠 결제위젯 + 승인 API + 자동결제(빌링키) 흐름으로 안전한 결제 플로우를 만듭니다.
> 결제 성공, 실패, 취소, 갱신, 해지까지 구독 생명주기를 다룹니다.

---

## 📋 목표

1. 토스페이먼츠 결제 구조 이해 (결제위젯 + 승인 API)
2. 결제/구독 데이터 모델 설계
3. 구독 시작 (월 9,900원 예시) 구현
4. 결제 성공/실패/취소 처리
5. 빌링키 기반 자동결제 구현
6. 로컬 샌드박스로 검증

---

## 1️⃣ 왜 Toss Payments인가?

### 결제 처리의 핵심 원칙

```
클라이언트 화면만 믿으면 안 된다.
진짜 결제 상태는 토스페이먼츠 승인 API와 조회 API로 확정한다.
```

### 선택 이유

| 항목 | 토스페이먼츠 | 비고 |
|------|------|------|
| 한국 사업자 가입 | ✅ | 국내 PG |
| 카드 결제 | ✅ | 일반 결제 |
| 자동결제(빌링) | ✅ | 구독형 SaaS 적합 |
| 개발자 경험 | ✅ | 결제위젯 + 샌드박스 |
| 운영 편의성 | ✅ | 한국형 정산/현금영수증 |

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

## 9️⃣ 로컬 테스트 방법

### 샌드박스/테스트 키 사용

토스페이먼츠 개발자센터에서 샌드박스 키를 발급받고, 결제위젯이 샌드박스 환경에서 동작하는지 확인합니다.

### 확인 포인트

1. 결제위젯이 로드되는가
2. `successUrl`로 `paymentKey/orderId/amount`가 전달되는가
3. 승인 API가 성공하는가
4. subscription 상태가 `active`로 바뀌는가
5. billingKey 발급 후 자동결제가 되는가

---

## ✅ 챕터 9 체크리스트

- [ ] 토스페이먼츠 결제위젯으로 구독 결제를 시작할 수 있다
- [ ] 승인 API로 결제 결과를 서버에서 확정한다
- [ ] `active / past_due / canceled` 상태를 DB에 반영한다
- [ ] billingKey 기반 자동결제를 구현했다
- [ ] 샌드박스 결제수단으로 성공/실패 흐름을 검증했다

---

## ➡️ 다음 챕터

10장에서는 사용자별 결제/구독 상태를 확인하고 관리할 수 있는 **대시보드**를 구현합니다.
