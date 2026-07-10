# 환경 설정

## 환경 변수 설정

### 필수 환경 변수

`.env` 파일에 다음 변수를 추가하세요:

```bash
# 토스페이먼츠 API 키
TOSS_CLIENT_KEY=test_ck_xxx          # 결제위젯 연동 키
TOSS_SECRET_KEY=test_sk_xxx          # API 시크릿
TOSS_PRICE_AMOUNT=9900               # 월간 구독료 (원)
```

### 키 발급 받기

1. [토스페이먼츠 개발자 센터](https://developers.tosspayments.com/) 접속
2. API 키 관리 → 결제위젯 연동 키 발급
   - **중요:** API 개별 연동 키가 아닌 **결제위젯 연동 키**를 사용해야 함
3. API 시크릿 키 별도 발급

### dotenv-rails 젬

`Gemfile`에 이미 추가되어 있습니다:

```ruby
gem "dotenv-rails", groups: [:development, :test]
```

`.env` 파일은 **commit하지 말아야** 합니다. `.gitignore`에 포함되어 있습니다.

---

## 마이그레이션 & DB 스키마

### 마이그레이션 파일

`db/migrate/20260709155208_add_toss_fields_to_subscriptions.rb`

```ruby
class AddTossFieldsToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :toss_customer_key, :string
    add_column :subscriptions, :toss_billing_key, :string
    add_column :subscriptions, :toss_payment_key, :string
    add_column :subscriptions, :order_id, :string
    add_column :subscriptions, :status, :string, default: "pending"
    add_column :subscriptions, :current_period_start, :datetime
    add_column :subscriptions, :current_period_end, :datetime
    add_column :subscriptions, :cancel_at, :datetime
    add_column :subscriptions, :canceled_at, :datetime

    add_index :subscriptions, :toss_customer_key, unique: true
    add_index :subscriptions, :order_id, unique: true
  end
end
```

### 스키마 정보

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `toss_customer_key` | string | 토스 고객키 (user-{user_id} 형식) |
| `toss_billing_key` | string | 자동 결제용 빌링키 |
| `toss_payment_key` | string | 결제 트랜잭션 키 |
| `order_id` | string | chatdox-{user_id}-{timestamp} 형식 |
| `status` | string | pending, done, failed, canceled 중 하나 |
| `current_period_start` | datetime | 현재 구독 기간 시작일 |
| `current_period_end` | datetime | 현재 구독 기간 종료일 |
| `cancel_at` | datetime | 구독 취소 예약일 |
| `canceled_at` | datetime | 구독 실제 취소일 |

### 실행 방법

```bash
# 마이그레이션 실행
rails db:migrate

# 마이그레이션 확인
rails db:schema:dump
```
