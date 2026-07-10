# 토스페이먼츠 결제 시스템

**작성일:** 2026-07-10  
**상태:** ✅ 결제 성공까지 구현 완료

---

## 📋 구현 완료 항목

### 1. 마이그레이션 & DB 스키마
- ✅ 마이그레이션 파일: `db/migrate/20260709155208_add_toss_fields_to_subscriptions.rb`
- ✅ 컬럼 추가:
  - `toss_customer_key` (유니크)
  - `toss_billing_key`
  - `toss_payment_key`
  - `order_id` (유니크)
  - `status` (기본값: "pending")
  - `current_period_start`, `current_period_end`
  - `cancel_at`, `canceled_at`

### 2. 모델 관계설정
- ✅ `app/models/subscription.rb`: 토스페이먼츠 필드 검증
- ✅ `app/models/user.rb`: `has_one :subscription`, `subscribed?` 메서드
  - 구독 상태: `status == "active" && current_period_end > Time.current`

### 3. 결제 API 클라이언트
- ✅ `app/services/toss_payments/client.rb`: 
  - Base64 인증 헤더
  - `post_json` / `get_json` 메서드
  - 에러 처리

- ✅ `app/services/toss_payments/billing_charge.rb`: 자동결제 API

### 4. 컨트롤러
- ✅ `app/controllers/billing_controller.rb`:
  - `checkout`: 주문 ID 생성, 결제 위젯 렌더링
  - `success`: 토스 결제 승인 API 호출, subscription 저장
  - `cancel`: 결제 취소 처리

- ✅ `app/controllers/billing_auths_controller.rb`: 빌링키 발급

- ✅ `app/controllers/webhooks/toss_payments_controller.rb`: 웹훅 수신 (향후 활용)

### 5. 뷰
- ✅ `app/views/billing/checkout.html.erb`:
  - 토스페이먼츠 결제위젯 SDK 로드
  - 결제 위젯 렌더링
  - 에러 로깅

- ✅ `app/views/landing/_pricing.html.erb`:
  - 결제 버튼 연결 (`link_to billing_checkout_path`)

### 6. 라우팅
- ✅ `config/routes.rb`:
  - `GET /billing/checkout` → 결제 페이지
  - `GET /billing/success` → 결제 승인
  - `GET /billing/cancel` → 결제 취소
  - `POST /billing/auths` → 빌링키 발급
  - `POST /webhooks/toss_payments` → 웹훅

---

## 🚀 다음 단계 (미구현)

- [ ] 구독 상태 대시보드 표시
- [ ] 구독 해지 기능
- [ ] 결제 이력 조회
- [ ] 자동 갱신 결제 (빌링키 활용)
- [ ] Webhook 상태 동기화
- [ ] 결제 실패/만료 안내 배너
