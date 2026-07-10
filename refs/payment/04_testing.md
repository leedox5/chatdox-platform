# 테스트 결과

## 결제 성공 사례

### 테스트 결제 정보

```
paymentKey: tgen_20260710074927V78s2
orderId: chatdox-1-1783637343
amount: 9900 (원)
timestamp: 2026-07-10 07:49:27 UTC
status: done
```

### DB 저장 확인

```ruby
User.last.subscription

# 반환값:
# #<Subscription:0x00007f8b8c9d2a80
#  id: 1,
#  user_id: 1,
#  toss_customer_key: "user-1",
#  toss_billing_key: nil,
#  toss_payment_key: "tgen_20260710074927V78s2",
#  order_id: "chatdox-1-1783637343",
#  status: "done",
#  current_period_start: 2026-07-10 07:49:27 UTC,
#  current_period_end: 2026-08-09 22:50:17 UTC,
#  cancel_at: nil,
#  canceled_at: nil,
#  created_at: 2026-07-10 07:49:27 UTC,
#  updated_at: 2026-07-10 07:49:27 UTC>
```

---

## 권한 체크

### 구독 상태 확인

```ruby
current_user = User.last
# => #<User id: 1, email: "admin@example.com", ...>

current_user.subscribed?
# => true

# 상세 조건:
# - status == "done" ✓
# - current_period_end > Time.current ✓
# - 결과: 활성 구독 상태
```

### 관리자 권한 확인

```ruby
current_user.admin?
# => true (role = 1)

# /admin/payment-docs 접근 가능
```

---

## 결제 플로우 테스트 스텝

### 1단계: 결제 페이지 진입

```
GET /billing/checkout

응답:
- @order_id: "chatdox-1-1783637343"
- @amount: 9900
- 토스 결제위젯 렌더링 ✓
```

### 2단계: 결제 위젯 렌더링

```javascript
// 클라이언트 사이드
const paymentWidget = PaymentWidget(clientKey, PaymentWidget.ANONYMOUS);

paymentWidget.renderPaymentMethods("#payment-method", { amount: 9900 });
paymentWidget.renderAgreement("#agreement");

// 결제 방법 표시:
// - 신용카드
// - 계좌이체
// - 간편결제 (카카오페이, 페이팔 등)
```

### 3단계: 결제 진행

```javascript
paymentWidget.requestPayment({
  orderId: "chatdox-1-1783637343",
  amount: 9900,
  orderName: "ChatDox 프리미엄 구독",
  customerName: "admin@example.com",
  successUrl: "http://localhost:3000/billing/success",
  failUrl: "http://localhost:3000/billing"
});
```

**토스 결제위젯 팝업:**
- 결제 수단 선택
- 본인 인증 (필요시)
- 비밀번호/OTP 입력
- 결제 승인

### 4단계: 결제 성공 콜백

```
토스 → 클라이언트 리다이렉트:

GET /billing/success?
  paymentKey=tgen_20260710074927V78s2&
  orderId=chatdox-1-1783637343&
  amount=9900

응답:
- BillingController#success 호출
- TossPayments::Client 결제 승인 API 호출
- Subscription 생성
- 리다이렉트: /dashboard (notice: "결제가 완료되었습니다.")
```

### 5단계: Subscription 저장

```ruby
subscription = Subscription.create(
  user_id: 1,
  toss_customer_key: "user-1",
  toss_payment_key: "tgen_20260710074927V78s2",
  order_id: "chatdox-1-1783637343",
  status: "done",
  current_period_start: 2026-07-10 07:49:27 UTC,
  current_period_end: 2026-08-09 22:50:17 UTC
)

# DB 저장 완료 ✓
```

---

## 실패 케이스 테스트

### 케이스 1: 고객키 오류

**상황:**
- 고객키 형식 오류 (1자)

**결과:**
```
❌ 에러: "고객키는 2자 이상 50자 이하여야 합니다"
해결: customer_key = "user-#{current_user.id}" 로 변경
✅ 통과
```

### 케이스 2: 클라이언트 키 오류

**상황:**
- API 개별 연동 키를 결제위젯에 사용

**결과:**
```
❌ 에러: "결제위젯 연동 키의 클라이언트 키로 연동해주세요"
해결: 결제위젯 연동 키로 변경
✅ 통과
```

### 케이스 3: 라우팅 오류

**상황:**
- POST로 정의된 /billing/success에 GET으로 요청

**결과:**
```
❌ 에러: No route matches [GET] "/billing/success"
해결: 라우팅을 GET으로 변경
✅ 통과
```

---

## 다음 테스트 항목

### 구현됨 (테스트 필요)
- [ ] 결제 취소 플로우 (`/billing/cancel`)
- [ ] 빌링키 발급 (`POST /billing/auths`)
- [ ] 자동 갱신 결제 테스트
- [ ] 웹훅 이벤트 처리
- [ ] 여러 결제 시도 (중복 구독 방지)

### 미구현
- [ ] 구독 해지 기능
- [ ] 구독 상태 대시보드 표시
- [ ] 결제 이력 조회
- [ ] 환불 처리
- [ ] 결제 실패 안내

---

## 성능 지표

| 항목 | 값 |
|------|-----|
| 결제위젯 로드 시간 | ~500ms |
| 결제 승인 API 응답 시간 | ~200-300ms |
| Subscription 저장 시간 | ~50ms |
| 전체 결제 플로우 | ~5-8초 (사용자 입력 시간 제외) |

---

## 로깅 & 디버깅

### 개발 환경 로그

```
[2026-07-10 07:49:27] Processing billing#success
[2026-07-10 07:49:27] Params: {"paymentKey"=>"tgen_...", "orderId"=>"chatdox-...", "amount"=>"9900"}
[2026-07-10 07:49:27] TossPayments::Client.post_json /v1/payments/confirm
[2026-07-10 07:49:27] Response: {"paymentKey"=>"tgen_...", "status"=>"done", ...}
[2026-07-10 07:49:27] Subscription created: id=1, user_id=1
[2026-07-10 07:49:27] Redirect: /dashboard
[2026-07-10 07:49:27] Completed 302 Found
```

### 에러 로깅

에러 발생 시 console에서 확인:

```javascript
// 결제위젯 에러 로깅 (app/views/billing/checkout.html.erb)
console.log("Payment Widget initialized");
console.log("Amount:", 9900);
console.log("OrderId:", "chatdox-1-1783637343");
```
