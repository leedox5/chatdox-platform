# 6. Database & Migrations

> Rails의 데이터베이스 설계와 Migration 시스템을 이해합니다.
> Chatdox 플랫폼의 핵심 테이블을 직접 만들어봅니다.

---

## 📋 목표

1. **Migration** 개념 이해
2. **Schema** 설계 방법
3. **Chatdox 핵심 테이블** 생성
4. **Active Record** 로 데이터 조작

---

## 1️⃣ Migration이란?

### 개념

```
Migration = 데이터베이스 변경 이력서

코드로 DB 스키마를 관리합니다.
- 테이블 추가/삭제
- 컬럼 추가/수정/삭제
- 인덱스 설정
```

### 왜 Migration을 사용하나?

| 방법 | 문제점 |
|------|--------|
| DB에 직접 수정 | 팀원과 공유 불가, 이력 없음 |
| SQL 파일 공유 | 순서 관리 어려움, 충돌 위험 |
| **Migration** | ✅ 코드로 관리, Git으로 공유, 순서 보장 |

---

## 2️⃣ Migration 기본 사용법

### 생성

```bash
# 모델 + Migration 동시 생성
rails generate model User email:string name:string

# Migration만 생성 (테이블 변경용)
rails generate migration AddPhoneToUsers phone:string
```

### 실행

```bash
rails db:migrate          # 미적용 Migration 실행
rails db:rollback         # 마지막 Migration 취소
rails db:migrate:status   # 적용 상태 확인
```

### 파일 구조

```
db/
├── migrate/
│   ├── 20260709000001_create_users.rb
│   ├── 20260709000002_create_subscriptions.rb
│   └── 20260709000003_add_phone_to_users.rb
└── schema.rb              # 현재 DB 상태 (자동 생성)
```

---

## 3️⃣ Chatdox 핵심 테이블 설계

### ERD (Entity Relationship Diagram)

```
users
  id, email, name, password_digest
  created_at, updated_at
    |
    | has_one
    ↓
subscriptions
  id, user_id, plan_type, status
  started_at, expires_at
  created_at, updated_at
```

---

## 4️⃣ users 테이블

### Migration 파일

```ruby
# db/migrate/20260709000001_create_users.rb

class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string  :email,           null: false
      t.string  :name,            null: false
      t.string  :password_digest, null: false

      t.timestamps  # created_at, updated_at 자동 추가
    end

    add_index :users, :email, unique: true  # 이메일 중복 방지
  end
end
```

### 생성 명령어

```bash
rails generate model User email:string:index name:string password_digest:string
rails db:migrate
```

### User 모델

```ruby
# app/models/user.rb

class User < ApplicationRecord
  has_secure_password  # password_digest 자동 처리

  has_one :subscription, dependent: :destroy

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name,  presence: true
end
```

---

## 5️⃣ subscriptions 테이블

### Migration 파일

```ruby
# db/migrate/20260709000002_create_subscriptions.rb

class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :user,      null: false, foreign_key: true
      t.string     :plan_type, null: false, default: "free"
      t.string     :status,    null: false, default: "active"
      t.datetime   :started_at
      t.datetime   :expires_at

      t.timestamps
    end
  end
end
```

### 생성 명령어

```bash
rails generate model Subscription user:references plan_type:string status:string started_at:datetime expires_at:datetime
rails db:migrate
```

### Subscription 모델

```ruby
# app/models/subscription.rb

class Subscription < ApplicationRecord
  belongs_to :user

  PLANS = %w[free basic premium].freeze

  validates :plan_type, inclusion: { in: PLANS }
  validates :status,    inclusion: { in: %w[active inactive cancelled] }

  def active?
    status == "active"
  end

  def premium?
    plan_type == "premium"
  end
end
```

---

## 6️⃣ 컬럼 추가 (Migration 변경)

기존 테이블에 컬럼을 추가할 때:

```bash
# Migration 파일 생성
rails generate migration AddAvatarToUsers avatar_url:string
```

```ruby
# db/migrate/20260709000004_add_avatar_to_users.rb

class AddAvatarToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :avatar_url, :string
  end
end
```

```bash
rails db:migrate
```

---

## 7️⃣ Active Record CRUD

### Create (생성)

```ruby
# Rails Console에서
user = User.create!(
  email: "test@chatdox.com",
  name: "테스터",
  password: "password123"
)
```

### Read (조회)

```ruby
User.all                          # 전체 조회
User.find(1)                      # ID로 조회
User.find_by(email: "test@...")   # 조건 조회
User.where(name: "테스터")         # 복수 조회
```

### Update (수정)

```ruby
user = User.find(1)
user.update!(name: "새이름")
```

### Delete (삭제)

```ruby
user = User.find(1)
user.destroy
```

---

## 8️⃣ Schema 확인

Migration 실행 후 `db/schema.rb`가 자동 업데이트됩니다:

```ruby
# db/schema.rb (자동 생성, 수동 수정 금지)

ActiveRecord::Schema[8.1].define(version: 2026_07_09_000002) do
  create_table "users", force: :cascade do |t|
    t.string   "email",           null: false
    t.string   "name",            null: false
    t.string   "password_digest", null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.index    ["email"],         unique: true
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "user_id",    null: false
    t.string   "plan_type",  default: "free"
    t.string   "status",     default: "active"
    t.datetime "started_at"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index    ["user_id"]
  end
end
```

---

## 9️⃣ 실전 체크리스트

### 새 테이블 추가 시
- [ ] `rails generate model ModelName ...` 실행
- [ ] Migration 파일 내용 확인 (null: false, default 등)
- [ ] `rails db:migrate` 실행
- [ ] `db/schema.rb` 변경 확인
- [ ] Model validation 추가

### 기존 테이블 변경 시
- [ ] `rails generate migration DescriptiveName ...` 실행
- [ ] Migration 파일 확인
- [ ] `rails db:migrate` 실행
- [ ] **절대 schema.rb 직접 수정 금지!**

---

## 🎯 핵심 원칙

| 원칙 | 설명 |
|------|------|
| **Migration으로만 변경** | DB를 직접 수정하지 않는다 |
| **null: false 기본값** | 필수 컬럼은 null 허용 안 함 |
| **인덱스 설정** | 자주 조회하는 컬럼에 index 추가 |
| **schema.rb는 자동** | 수동 수정 절대 금지 |

---

## 📚 다음 단계

✅ 이제 데이터베이스 설계를 이해했습니다!

다음에는:
- **07장: Authentication with Devise** - 회원가입/로그인
- **08장: Authorization** - 접근 권한 제어
