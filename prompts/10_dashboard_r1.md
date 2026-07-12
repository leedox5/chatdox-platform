---
title: "10 Dashboard R1: 사용자 대시보드 구현"
description: "구독 상태, Trial 기간, 학습 진도와 빠른 이동을 제공하는 사용자 전용 대시보드 구현"
version: "R1"
---

# 10 Dashboard R1: 사용자 대시보드 구현

## 🎯 목표

Platform 프로젝트에 사용자 전용 대시보드를 구현합니다.

1. ✅ Devise 로그인 사용자만 접근
2. ✅ Pundit `DashboardPolicy`로 권한 확인
3. ✅ Trial/구독/결제 지연 상태 표시
4. ✅ 챕터 완료 기록과 학습 진도 표시
5. ✅ 최근 완료 및 다음 추천 챕터 제공
6. ✅ 반응형 Tailwind CSS UI 구현

---

## 📋 선행 조건

| 프롬프트 | 사용하는 기능 |
|---|---|
| `07_authentication_r1.md` | Devise, `current_user`, `authenticate_user!` |
| `08_authorization_r1.md` | Pundit, `DashboardPolicy`, Trial 메서드 |
| `09_payment_r1.md` | `Subscription`, 결제 상태, `billing_checkout_path` |

---

## 📋 필수 단계

### Step 1: 학습 진도 모델 생성

```bash
rails generate model ChapterProgress user:references chapter_id:string completed_at:datetime
```

**파일: `db/migrate/xxxxxx_create_chapter_progresses.rb`**

```ruby
class CreateChapterProgresses < ActiveRecord::Migration[8.0]
  def change
    create_table :chapter_progresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :chapter_id, null: false
      t.datetime :completed_at
      t.timestamps
    end

    add_index :chapter_progresses, [:user_id, :chapter_id], unique: true
  end
end
```

```bash
rails db:migrate
```

> Migration 버전은 제너레이터가 만든 값을 유지합니다.

---

### Step 2: 모델 관계와 검증 추가

**파일: `app/models/user.rb`**

```ruby
class User < ApplicationRecord
  # 기존 Devise, role, Trial 설정 유지
  has_one :subscription, dependent: :destroy
  has_many :chapter_progresses, dependent: :destroy
end
```

**파일: `app/models/chapter_progress.rb`**

```ruby
class ChapterProgress < ApplicationRecord
  belongs_to :user

  validates :chapter_id,
            presence: true,
            uniqueness: { scope: :user_id },
            format: { with: /\A(0[1-9]|1[0-9]|20)\z/ }

  scope :completed, -> { where.not(completed_at: nil) }

  def completed?
    completed_at.present?
  end
end
```

챕터 ID는 `"01"`~`"20"` 형식으로 통일합니다.

---

### Step 3: 커리큘럼 목록 공통화

DocsController와 DashboardController가 같은 목록을 사용하도록 분리합니다.

**파일: `app/models/curriculum.rb`**

```ruby
class Curriculum
  CHAPTERS = [
    { id: "01", slug: "01_overview", title: "채독스 전체 구조 이해" },
    { id: "02", slug: "02_rails_basics", title: "Ruby on Rails 기초" },
    { id: "03", slug: "03_dev_setup", title: "개발 환경 설정" },
    { id: "04", slug: "04_landing_page", title: "랜딩 페이지 구현" },
    { id: "05", slug: "05_project_structure", title: "프로젝트 구조" },
    { id: "06", slug: "06_database", title: "데이터베이스" },
    { id: "07", slug: "07_authentication", title: "인증 (Devise)" },
    { id: "08", slug: "08_authorization", title: "권한 (Pundit)" },
    { id: "09", slug: "09_payment", title: "결제 (Toss / PortOne)" },
    { id: "10", slug: "10_dashboard", title: "사용자 대시보드" },
    { id: "11", slug: "11_admin", title: "관리자 대시보드" },
    { id: "12", slug: "12_email", title: "Email & 알림" },
    { id: "13", slug: "13_file_upload", title: "파일 업로드" },
    { id: "14", slug: "14_api", title: "API 설계 & JSON" },
    { id: "15", slug: "15_testing", title: "테스트" },
    { id: "16", slug: "16_performance", title: "성능 최적화 & 캐싱" },
    { id: "17", slug: "17_security", title: "보안 & OWASP" },
    { id: "18", slug: "18_deployment", title: "배포" },
    { id: "19", slug: "19_monitoring", title: "모니터링" },
    { id: "20", slug: "20_launch", title: "런칭 & 운영" }
  ].freeze

  def self.all = CHAPTERS

  def self.find(id)
    normalized_id = id.to_s.rjust(2, "0")
    CHAPTERS.find { |chapter| chapter[:id] == normalized_id }
  end
end
```

기존 `DocsController::CHAPTERS`는 `Curriculum.all`로 교체하되 파일 존재 및 `DocPolicy` 검사는 유지합니다.

---

### Step 4: 대시보드 라우트와 컨트롤러

```bash
rails generate controller Dashboards show
```

**파일: `config/routes.rb`**

```ruby
resource :dashboard, only: :show

resources :chapter_progresses, only: :create do
  delete :destroy, on: :collection
end
```

제너레이터가 추가한 `get "dashboards/show"`는 삭제합니다.

**파일: `app/controllers/dashboards_controller.rb`**

```ruby
class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize :dashboard, :access?

    @subscription = current_user.subscription
    @completed_ids = current_user.chapter_progresses
                                 .completed
                                 .order(completed_at: :desc)
                                 .pluck(:chapter_id)
    @total_chapters = Curriculum.all.size
    @completed_count = @completed_ids.size
    @progress_percent = progress_percent(@completed_count, @total_chapters)
    @recent_chapters = @completed_ids.first(3).filter_map { |id| Curriculum.find(id) }
    @next_chapter = Curriculum.all.find { |ch| !@completed_ids.include?(ch[:id]) }
  end

  private

  def progress_percent(completed_count, total_count)
    return 0 if total_count.zero?

    ((completed_count.to_f / total_count) * 100).round
  end
end
```

개인 데이터는 반드시 `current_user` 연관관계에서 조회합니다.

---

### Step 5: Policy와 로그인 후 이동

**파일: `app/policies/dashboard_policy.rb`**

```ruby
class DashboardPolicy < ApplicationPolicy
  def initialize(user, _record = nil)
    @user = user
  end

  def access?
    @user.present?
  end
end
```

**파일: `app/controllers/application_controller.rb`**

기존 Pundit 설정에 다음 메서드를 추가합니다.

```ruby
protected

def after_sign_in_path_for(_resource)
  dashboard_path
end
```

---

### Step 6: 구독 상태 헬퍼

**파일: `app/helpers/dashboards_helper.rb`**

```ruby
module DashboardsHelper
  BADGES = {
    "active" => ["구독 중", "bg-emerald-100 text-emerald-700"],
    "past_due" => ["결제 확인 필요", "bg-amber-100 text-amber-700"],
    "canceled" => ["해지됨", "bg-gray-100 text-gray-700"],
    "expired" => ["만료됨", "bg-red-100 text-red-700"],
    "pending" => ["결제 대기", "bg-blue-100 text-blue-700"]
  }.freeze

  def subscription_badge(subscription)
    label, classes = BADGES.fetch(
      subscription&.status,
      ["무료 Trial", "bg-violet-100 text-violet-700"]
    )
    tag.span(label, class: "rounded-full px-3 py-1 text-sm font-semibold #{classes}")
  end

  def subscription_period_text(user, subscription)
    if subscription&.status == "active" && subscription.current_period_end.present?
      "이용 종료일: #{I18n.l(subscription.current_period_end.to_date)}"
    elsif user.trial_active?
      "무료 Trial #{user.trial_days_remaining}일 남음"
    else
      "이용 가능한 구독이 없습니다"
    end
  end
end
```

구독 상태는 대시보드에서 변경하지 않습니다. 09 Payment의 승인/웹훅이 상태의 단일 출처입니다.

---

### Step 7: 대시보드 UI

**파일: `app/views/dashboards/show.html.erb`**

```erb
<main class="mx-auto max-w-6xl px-4 py-10 sm:px-6 lg:px-8">
  <header class="mb-8 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
    <div>
      <p class="text-sm font-semibold text-blue-600">MY DASHBOARD</p>
      <h1 class="mt-1 text-3xl font-bold text-gray-900">
        안녕하세요, <%= current_user.email %>님
      </h1>
      <p class="mt-2 text-gray-600">오늘도 다음 챕터부터 이어서 학습해 보세요.</p>
    </div>
    <%= link_to "전체 문서 보기", docs_path,
      class: "rounded-lg bg-blue-600 px-4 py-2.5 font-semibold text-white" %>
  </header>

  <section class="grid gap-5 md:grid-cols-3" aria-label="이용 현황">
    <article class="rounded-2xl border border-gray-200 bg-white p-6 shadow-sm">
      <div class="flex items-center justify-between">
        <h2 class="font-semibold">이용 상태</h2>
        <%= subscription_badge(@subscription) %>
      </div>
      <p class="mt-5 text-sm text-gray-600">
        <%= subscription_period_text(current_user, @subscription) %>
      </p>
      <% unless current_user.subscribed? %>
        <%= link_to "구독 시작", billing_checkout_path,
          class: "mt-4 inline-block font-semibold text-blue-600" %>
      <% end %>
    </article>

    <article class="rounded-2xl border border-gray-200 bg-white p-6 shadow-sm md:col-span-2">
      <div class="flex justify-between">
        <h2 class="font-semibold">학습 진도</h2>
        <strong class="text-2xl text-blue-600"><%= @progress_percent %>%</strong>
      </div>
      <p class="mt-2 text-sm text-gray-600">
        전체 <%= @total_chapters %>개 중 <%= @completed_count %>개 완료
      </p>
      <div class="mt-5 h-3 overflow-hidden rounded-full bg-gray-100"
           role="progressbar" aria-valuenow="<%= @progress_percent %>"
           aria-valuemin="0" aria-valuemax="100">
        <div class="h-full rounded-full bg-blue-600"
             style="width: <%= @progress_percent %>%"></div>
      </div>
    </article>
  </section>

  <section class="mt-8 grid gap-8 lg:grid-cols-3">
    <article class="rounded-2xl border border-gray-200 bg-white p-6 lg:col-span-2">
      <h2 class="text-lg font-bold">최근 완료한 챕터</h2>
      <% if @recent_chapters.any? %>
        <ul class="mt-4 divide-y">
          <% @recent_chapters.each do |chapter| %>
            <li class="flex items-center justify-between py-4">
              <span><%= chapter[:id] %>. <%= chapter[:title] %></span>
              <%= link_to "다시 보기", doc_path(chapter[:id]),
                class: "font-semibold text-blue-600" %>
            </li>
          <% end %>
        </ul>
      <% else %>
        <p class="mt-4 rounded-xl bg-gray-50 p-6 text-gray-600">
          아직 완료한 챕터가 없습니다.
        </p>
      <% end %>
    </article>

    <aside class="rounded-2xl bg-gray-900 p-6 text-white">
      <p class="text-sm font-semibold text-blue-300">NEXT STEP</p>
      <% if @next_chapter %>
        <h2 class="mt-3 text-xl font-bold"><%= @next_chapter[:title] %></h2>
        <%= link_to "이어서 학습", doc_path(@next_chapter[:id]),
          class: "mt-6 block rounded-lg bg-white px-4 py-2.5 text-center font-semibold text-gray-900" %>
      <% else %>
        <h2 class="mt-3 text-xl font-bold">모든 챕터를 완료했습니다!</h2>
      <% end %>
    </aside>
  </section>
</main>
```

---

### Step 8: 챕터 완료/취소

**파일: `app/controllers/chapter_progresses_controller.rb`**

```ruby
class ChapterProgressesController < ApplicationController
  before_action :authenticate_user!

  def create
    chapter = Curriculum.find(params[:chapter_id])
    return head :not_found unless chapter

    progress = current_user.chapter_progresses.find_or_initialize_by(chapter_id: chapter[:id])
    progress.update!(completed_at: Time.current)
    redirect_to doc_path(chapter[:id]), notice: "완료한 챕터로 표시했습니다."
  end

  def destroy
    chapter = Curriculum.find(params[:chapter_id])
    return head :not_found unless chapter

    current_user.chapter_progresses.find_by(chapter_id: chapter[:id])&.destroy!
    redirect_to doc_path(chapter[:id]), notice: "완료 표시를 취소했습니다."
  end
end
```

**파일: `app/views/docs/show.html.erb`** 하단:

```erb
<% if user_signed_in? %>
  <% progress = current_user.chapter_progresses.find_by(chapter_id: @doc[:id]) %>
  <% if progress&.completed? %>
    <%= button_to "완료 표시 취소",
      chapter_progresses_path(chapter_id: @doc[:id]), method: :delete %>
  <% else %>
    <%= button_to "이 챕터 완료",
      chapter_progresses_path(chapter_id: @doc[:id]), method: :post %>
  <% end %>
<% end %>
```

---

### Step 9: 헤더 링크와 테스트

로그인 메뉴에 링크를 추가합니다.

```erb
<%= link_to "대시보드", dashboard_path if user_signed_in? %>
```

```bash
rails db:migrate
rails s
```

```text
1. 비로그인 /dashboard → 로그인 페이지
2. Trial → 무료 Trial 배지, 남은 일수, 구독 시작 버튼
3. Subscriber → 구독 중 배지, 이용 종료일
4. /docs/01 완료 → 진도율 증가, 최근 완료 표시
5. 완료 취소 → 진도율 감소
```

---

### Step 10: 배포

```bash
rails test
git status
git diff --check
git add app config db
git commit -m "feat: Add subscriber dashboard and chapter progress"
git push origin main
```

Railway 배포 후 마이그레이션 실행 여부를 확인합니다.

---

## 🧯 트러블슈팅

| 문제 | 원인 | 해결 |
|---|---|---|
| `/dashboard` 404 | 단수형 route 누락 | `resource :dashboard` 확인 |
| 로그인 후 홈으로 이동 | Devise 기본 redirect | `after_sign_in_path_for` 추가 |
| 권한 오류 | Policy 불일치 | `DashboardPolicy#access?` 확인 |
| 진도율이 0% | `completed_at` 미저장 | 완료 시 `Time.current` 저장 |
| 챕터 중복 집계 | 인덱스 누락 | 복합 유니크 인덱스 추가 |
| 타 사용자 기록 노출 | 전체 테이블 조회 | `current_user.chapter_progresses` 사용 |
| 결제 후 Trial 표시 | 상태가 `active`가 아님 | 09 Payment 승인/웹훅 확인 |

---

## ✅ 구현 체크리스트

### 파일 생성/수정

- [ ] `ChapterProgress` 모델/마이그레이션
- [ ] `Curriculum` 공통 목록
- [ ] `DashboardsController#show`
- [ ] `ChapterProgressesController`
- [ ] `DashboardsHelper`
- [ ] `dashboards/show.html.erb`
- [ ] User 연관관계와 dashboard/progress 라우트
- [ ] 문서 완료 버튼과 헤더 링크

### 검증

- [ ] 비로그인 대시보드 접근 불가
- [ ] Trial/Subscriber/past_due 상태 구분
- [ ] 사용자별 완료 기록 및 중복 방지
- [ ] 진도율, 최근 완료, 다음 챕터 표시
- [ ] 반응형 레이아웃 확인
- [ ] Railway 마이그레이션 확인

---

## 📌 핵심 메커니즘

```text
/dashboard
  ↓ authenticate_user!
  ↓ DashboardPolicy#access?
  ↓ current_user.subscription
  ↓ current_user.chapter_progresses.completed
  ↓ 진도율 / 최근 완료 / 다음 챕터
  ↓ 대시보드 렌더링
```

UI에서 버튼을 숨기는 것만으로 권한을 보호할 수 없습니다. 인증, Policy, 사용자 범위 쿼리를 서버에서 모두 적용합니다.

---

## ✅ 완료 후 결과

| 항목 | 상태 |
|---|---|
| 로그인 사용자 전용 대시보드 | ✅ |
| Pundit 접근 검사 | ✅ |
| Trial/구독 상태 카드 | ✅ |
| 챕터 완료/취소 및 진도율 | ✅ |
| 최근 완료/다음 챕터 | ✅ |
| 반응형 Tailwind UI | ✅ |
| 로컬 테스트/배포 | ✅ |

---

## 🚀 다음 단계

- **11 Admin Dashboard** - 사용자/구독/결제 운영 화면
- **12 Email & 알림** - 결제 및 학습 알림
- **15 Testing** - 대시보드 테스트 강화

---

**마지막 업데이트:** 2026-07-10
