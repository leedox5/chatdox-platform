# PortOne 결제 테스트 가이드

**작성일:** 2026-07-10  
**상태:** PortOne V2 선택 연동 테스트 절차

---

## 1. PortOne 콘솔 준비

PortOne 관리자 콘솔에서 테스트 연동 정보를 준비합니다.

- 테스트 Store ID 확인
- 테스트 PG 채널 등록 후 Channel Key 확인
- V2 API Secret 발급
- Webhook Secret 발급
- 웹훅 URL 등록: `https://your-domain.com/webhooks/portone`

로컬에서 웹훅까지 테스트하려면 ngrok 같은 공개 HTTPS 터널이 필요합니다.

---

## 2. 환경 변수 설정

```bash
PAYMENT_PROVIDER=portone
PAYMENT_PRICE_AMOUNT=9900
PAYMENT_CURRENCY=KRW

PORTONE_STORE_ID=store-xxx
PORTONE_CHANNEL_KEY=channel-key-xxx
PORTONE_API_SECRET=portone-api-secret
PORTONE_WEBHOOK_SECRET=whsec_xxx
```

주의:

- `PORTONE_API_SECRET`과 `PORTONE_WEBHOOK_SECRET`은 서버에서만 사용합니다.
- 브라우저에는 Store ID와 Channel Key만 전달합니다.
- 기존 토스 결제를 다시 테스트하려면 `PAYMENT_PROVIDER=toss`로 되돌립니다.

---

## 3. 로컬 서버 실행

```bash
bin/dev
```

로그인 후 결제 페이지에 접속합니다.

```text
GET /billing/checkout
```

PortOne 모드에서는 결제 페이지에서 PortOne Browser SDK V2를 로드하고 `PortOne.requestPayment()`를 호출합니다.

---

## 4. 브라우저 결제 테스트

1. 로그인
2. `/billing/checkout` 접속
3. `결제하기` 클릭
4. PortOne 결제창에서 테스트 카드로 결제
5. 결제 성공 후 서버가 `/billing/success`로 결제 검증 요청
6. 서버가 PortOne API로 결제 단건을 재조회
7. 금액, 통화, 상태가 일치하면 구독 활성화
8. 대시보드로 이동

서버 검증 기준:

- `paymentId`가 서버에서 발급한 주문 ID와 일치
- `status == "PAID"`
- `amount.total == PAYMENT_PRICE_AMOUNT`
- `currency == PAYMENT_CURRENCY`

브라우저 성공 응답만으로 구독을 활성화하지 않습니다.

---

## 5. DB 저장 확인

결제 성공 후 Rails 콘솔 또는 runner로 구독과 결제 이력을 확인합니다.

```bash
bin/rails runner 'p User.last.subscription.attributes'
bin/rails runner 'p PaymentTransaction.last.attributes'
```

기대값:

```ruby
subscription.provider
# => "portone"

subscription.status
# => "active"

subscription.current_period_end.present?
# => true

PaymentTransaction.last.provider
# => "portone"

PaymentTransaction.last.status
# => "active"
```

### 실제 성공 결과

2026-07-10 로컬 테스트에서 PortOne 테스트 결제가 성공했고, 결제 완료 후 대시보드로 정상 이동했습니다.

Subscription 저장 결과:

```ruby
{
  id: 1,
  user_id: 1,
  provider: "portone",
  provider_customer_id: "user-1",
  status: "active",
  active: true,
  order_id: "chatdox-1-1783658052",
  current_period_start: "2026-07-10 04:36:27 UTC",
  current_period_end: "2026-08-10 04:36:27 UTC",
  billing_key_present: false
}
```

PaymentTransaction 저장 결과:

```ruby
{
  id: 2,
  subscription_id: 1,
  provider: "portone",
  provider_payment_id: "chatdox-1-1783658052",
  order_id: "chatdox-1-1783658052",
  status: "active",
  amount: 9900,
  currency: "KRW"
}
```

사용자 구독 판정:

```ruby
User.find(1).subscribed?
# => true
```

참고:

- 기존 `subscriptions.toss_*` 컬럼은 토스 회귀 테스트와 기존 데이터 보존을 위해 유지합니다.
- 현재 결제 공급자 기준은 `subscriptions.provider == "portone"`과 `payment_transactions.provider == "portone"`입니다.
- 이번 테스트는 일반 결제 성공 검증이며, PortOne billing key 발급은 별도 테스트가 필요합니다.

---

## 6. 웹훅 테스트

웹훅 URL:

```text
POST /webhooks/portone
```

테스트 방법:

1. PortOne 콘솔의 웹훅 호출 테스트 사용
2. 또는 실제 테스트 결제 후 웹훅 수신 확인
3. 서버 로그에서 `PortOne webhook` 에러가 없는지 확인
4. DB의 `subscriptions.status`와 `payment_transactions.status` 동기화 확인

처리 순서:

1. 원문 body와 요청 헤더로 웹훅 서명 검증
2. payload의 `data.paymentId` 추출
3. PortOne API로 결제 단건 재조회
4. 결제 상태를 내부 상태로 매핑
5. 구독과 결제 이력 업데이트

상태 매핑:

| PortOne 상태 | 내부 상태 |
|---|---|
| `PAID` | `active` |
| `CANCELLED` | `canceled` |
| `PARTIAL_CANCELLED` | `canceled` |
| `FAILED` | `past_due` |
| 그 외 | `pending` |

---

## 7. 토스 결제 회귀 테스트

PortOne 추가 후에도 기존 토스 결제가 반드시 유지되어야 합니다.

토스 모드로 변경:

```bash
PAYMENT_PROVIDER=toss
```

확인 항목:

- `/billing/checkout`에서 토스 결제위젯 렌더링
- 토스 테스트 결제 성공
- `GET /billing/success` 콜백 정상 처리
- `subscriptions.toss_payment_key` 저장
- `subscriptions.provider == "toss"`
- `payment_transactions.provider == "toss"`
- `current_user.subscribed? == true`

---

## 8. 문제 해결

| 문제 | 확인할 항목 |
|---|---|
| 결제 버튼이 `환경설정 오류`로 표시됨 | `PORTONE_STORE_ID`, `PORTONE_CHANNEL_KEY` 설정 여부 |
| 결제 성공 후 구독이 활성화되지 않음 | `PORTONE_API_SECRET`, 금액, 통화, `status == "PAID"` 여부 |
| 웹훅이 400을 반환함 | `PORTONE_WEBHOOK_SECRET`, Standard Webhooks 서명 헤더 |
| 로컬 웹훅이 오지 않음 | HTTPS 공개 터널 URL 등록 여부 |
| 토스 결제가 깨짐 | `PAYMENT_PROVIDER=toss`, `TOSS_CLIENT_KEY`, `TOSS_SECRET_KEY` |

---

## 9. 검증 명령

정적 검증:

```bash
bin/rubocop
bin/rails zeitwerk:check
```

provider 선택 확인:

```bash
PAYMENT_PROVIDER=portone bin/rails runner 'puts Payments::Gateway.current.provider'
PAYMENT_PROVIDER=toss bin/rails runner 'puts Payments::Gateway.current.provider'
```

기대값:

```text
portone
toss
```
