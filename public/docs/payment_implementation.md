# 09 Payment R1: 토스페이먼츠 구독 결제 구현 - 완료 기록

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

### 7. 환경 변수
- ✅ `dotenv-rails` 젬 추가
- ✅ `.env` 파일 생성:
  ```
  TOSS_CLIENT_KEY=test_ck_xxx (결제위젯 연동 키)
  TOSS_SECRET_KEY=test_sk_xxx (API 시크릿)
  TOSS_PRICE_AMOUNT=9900
  ```

---

## 🐛 해결된 이슈

### Issue 1: 고객키 검증 에러
**원인:** `customerKey`가 1자 (user id가 1)  
**해결:** `"user-#{current_user.id}"` 형태로 변경 (2자 이상)

### Issue 2: API 개별 연동 키 사용 불가
**원인:** API 개별 연동 키를 결제위젯에 사용  
**해결:** 토스 대시보드에서 **결제위젯 연동 키** 별도 발급 사용

### Issue 3: `Net::HTTP` 미로드
**원인:** `require 'net/http'` 누락  
**해결:** `app/services/toss_payments/client.rb`에 추가

### Issue 4: 라우팅 에러
**원인:** `/billing/success`를 POST로 정의했으나 결제위젯에서 GET으로 리다이렉트  
**해결:** `GET /billing/success` 로 변경

---

## ✅ 테스트 결과

### 결제 성공 사례
```
paymentKey: tgen_20260710074927V78s2
orderId: chatdox-1-1783637343
status: done
current_period_end: 2026-08-09 22:50:17 UTC
```

### DB 저장 확인
```ruby
User.last.subscription
# ✓ Subscription 존재
#   - status: done
#   - toss_payment_key: tgen_20260710074927V78s2
#   - order_id: chatdox-1-1783637343
#   - current_period_end: 2026-08-09 22:50:17 UTC
```

### 권한 체크
```ruby
User.last.subscribed?
# => true (status가 done이고 current_period_end가 미래)
```

---

## 📁 생성/수정된 파일 목록

| 파일 | 상태 |
|------|------|
| `db/migrate/20260709155208_add_toss_fields_to_subscriptions.rb` | 신규 + 실행 완료 |
| `app/services/toss_payments/client.rb` | 신규 |
| `app/services/toss_payments/billing_charge.rb` | 신규 |
| `app/controllers/billing_controller.rb` | 신규 |
| `app/controllers/billing_auths_controller.rb` | 신규 |
| `app/controllers/webhooks/toss_payments_controller.rb` | 신규 |
| `app/views/billing/checkout.html.erb` | 신규 |
| `app/models/subscription.rb` | 수정 |
| `app/models/user.rb` | 수정 |
| `config/routes.rb` | 수정 |
| `app/views/landing/_pricing.html.erb` | 수정 |
| `.env` | 신규 |
| `Gemfile` | 수정 (dotenv-rails 추가) |

---

## 🚀 다음 단계 (미구현)

- [ ] 구독 상태 대시보드 표시
- [ ] 구독 해지 기능
- [ ] 결제 이력 조회
- [ ] 자동 갱신 결제 (빌링키 활용)
- [ ] Webhook 상태 동기화
- [ ] 결제 실패/만료 안내 배너

---

## 📌 주요 학습사항

1. **토스페이먼츠 키 구분 중요**
   - API 개별 연동 키 ≠ 결제위젯 연동 키
   - 용도에 맞게 사용 필수

2. **고객키(customerKey) 포맷**
   - 2자 이상 50자 이하
   - 영문 대소문자, 숫자, 특수문자 (-, _, =, ., @) 만 허용

3. **리다이렉트 방식 확인**
   - 결제위젯 → GET 리다이렉트
   - 라우팅 메서드 일치 필수

4. **Ruby Net::HTTP 사용 시**
   - `require 'net/http'` 명시적 로드 필요
   - Base64 인코딩으로 Basic Auth 구현

---

**최종 커밋:** 토스페이먼츠 결제 시스템 구현 완료
