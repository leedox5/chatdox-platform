---
title: "08 Authorization R1: Pundit으로 권한 관리 구현"
description: "Platform에 Pundit 권한 시스템 구현 (Guest, Trial, Subscriber, Admin)"
version: "R1"
---

# 08 Authorization R1: Pundit으로 권한 관리 구현

## 🎯 목표

Platform 프로젝트에 권한 관리 시스템 구현:

1. ✅ Pundit 젬 설치 & 설정
2. ✅ Policy 파일 작성 (4가지 역할)
3. ✅ 문서 접근 제어 (1-5장 vs 6-20장)
4. ✅ 대시보드 보호 (로그인 필수)
5. ✅ UI에서 권한 표시 (🔒 아이콘)
6. ✅ 테스트 & 배포

---

## 📋 필수 단계

### Step 1: Pundit 설치

```bash
# Platform 폴더에서
cd ~/chatdox-platform

# Pundit 젬 추가
bundle add pundit

# Pundit 초기화
rails generate pundit:install

# 확인
ls app/policies/
# → application_policy.rb
```

---

### Step 2: User 모델 업데이트

**파일: `app/models/user.rb`**

역할과 Trial 메서드 추가:

```ruby
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  has_one :subscription
  
  # 역할 (enum)
  enum role: { user: 0, admin: 1 }
  
  # Trial 관련 메서드
  def trial_started_at
    created_at
  end
  
  def trial_remaining_seconds
    remaining = (trial_started_at + 7.days) - Time.current
    remaining.to_i > 0 ? remaining.to_i : 0
  end
  
  def trial_days_remaining
    days = (trial_remaining_seconds / 86400.0).ceil
    days > 0 ? days : 0
  end
  
  def trial_active?
    trial_remaining_seconds > 0
  end
  
  # Subscription 관련
  def subscribed?
    subscription&.active?
  end
  
  # 권한 확인 (UI용)
  def can_view_chapter?(chapter_num)
    return true if admin?
    return true if subscribed?
    return true if trial_active? && chapter_num <= 5
    chapter_num <= 2  # Guest: 1-2장
  end
end
```

---

### Step 3: Policy 파일 작성

**파일: `app/policies/doc_policy.rb`** (새로 생성)

```ruby
class DocPolicy < ApplicationPolicy
  attr_reader :user, :doc
  
  def initialize(user, doc)
    @user = user
    @doc = doc
  end
  
  # 문서 번호 추출 (doc[:id] = "05" → 5)
  def chapter_number
    @doc[:id].to_i
  end
  
  # Role: Guest (비로그인) - 1-2장만
  def view_as_guest?
    chapter_number <= 2
  end
  
  # Role: Trial (로그인 + 7일 이내) - 1-5장
  def view_as_trial?
    user&.trial_active? && chapter_number <= 5
  end
  
  # Role: Subscriber (유료) - 1-20장
  def view_as_subscriber?
    user&.subscribed? && chapter_number <= 20
  end
  
  # Role: Admin - 전체 접근
  def view_as_admin?
    user&.admin?
  end
  
  # 최종 판단: view? 메서드
  def view?
    return true if view_as_admin?
    return true if view_as_subscriber?
    return true if view_as_trial?
    return true if view_as_guest?
    false
  end
end
```

**파일: `app/policies/dashboard_policy.rb`** (새로 생성)

```ruby
class DashboardPolicy < ApplicationPolicy
  attr_reader :user
  
  def initialize(user, _record = nil)
    @user = user
  end
  
  # 대시보드 접근: 로그인 필수
  def access?
    user.present?
  end
  
  # 구독 정보 표시: Trial 또는 Subscriber
  def show_subscription?
    user.present? && (user.trial_active? || user.subscribed?)
  end
  
  # Admin 접근: 전체 기능
  def admin_access?
    user&.admin?
  end
end
```

---

### Step 4: ApplicationController 업데이트

**파일: `app/controllers/application_controller.rb`**

Pundit 포함 및 에러 처리:

```ruby
class ApplicationController < ActionController::Base
  include Pundit::Authorization
  
  # 권한 없을 때 처리
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  
  private
  
  def user_not_authorized
    flash[:alert] = "이 작업을 할 권한이 없습니다."
    redirect_to root_path
  end
end
```

---

### Step 5: DocsController 업데이트

**파일: `app/controllers/docs_controller.rb`**

기존 코드에 권한 체크 추가:

```ruby
class DocsController < ApplicationController
  DOCS_PATH = Rails.root.join("docs/curriculum")
  
  CHAPTERS = [
    { id: "01", slug: "01_overview", title: "채독스 전체 구조 이해" },
    { id: "02", slug: "02_rails_basics", title: "Ruby on Rails 기초" },
    { id: "03", slug: "03_dev_setup", title: "개발 환경 설정" },
    { id: "04", slug: "04_landing_page", title: "랜딩 페이지 구현" },
    { id: "05", slug: "05_project_structure", title: "프로젝트 구조" },
    { id: "06", slug: "06_database", title: "데이터베이스" },
    { id: "07", slug: "07_authentication", title: "인증 (Devise)" },
    { id: "08", slug: "08_authorization", title: "권한 (Pundit)" },
    # ... 09-20
  ].freeze
  
  def index
    @chapters = chapters_with_availability
  end
  
  def show
    # 문서 객체 (policy 확인용)
    @doc = { id: params[:id] }
    
    # 권한 확인! (여기서 에러 발생하면 rescue_from 처리)
    authorize @doc, policy_class: DocPolicy
    
    # 권한이 있으면 마크다운 렌더링
    @markdown_html = render_markdown(params[:id])
    @chapters = chapters_with_availability
  end
  
  private
  
  def chapters_with_availability
    CHAPTERS.map do |ch|
      file = DOCS_PATH.join("#{ch[:slug]}.md")
      policy = DocPolicy.new(current_user, ch)
      
      ch.merge(
        available: File.exist?(file),
        accessible: policy.view?  # 🔑 새로 추가!
      )
    end
  end
  
  def render_markdown(chapter_id)
    file = DOCS_PATH.join("#{chapter_id}.md")
    return "" unless File.exist?(file)
    
    markdown_content = File.read(file)
    renderer = Redcarpet::Render::HTML.new(
      hard_wrap: true,
      link_attributes: { target: "_blank" }
    )
    parser = Redcarpet::Markdown.new(renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      superscript: true
    )
    
    parser.render(markdown_content)
  end
end
```

---

### Step 6: 사이드바 UI 업데이트

**파일: `app/views/docs/show.html.erb`**

사이드바 부분 수정 (권한 표시):

```erb
<aside class="w-64 sticky top-0 bg-gray-50 p-4 h-screen overflow-y-auto border-r border-gray-200">
  <h3 class="font-bold text-lg mb-4 text-gray-800">📚 챕터</h3>
  
  <ul class="space-y-2">
    <% @chapters.each do |chapter| %>
      <li>
        <% if chapter[:available] %>
          <% if chapter[:accessible] %>
            <!-- 접근 가능: 파란색 링크 -->
            <div class="flex items-center gap-2">
              <%= link_to chapter[:title],
                doc_path(chapter[:slug]),
                class: "text-blue-600 hover:text-blue-800 hover:underline flex-1"
              %>
            </div>
          <% else %>
            <!-- 접근 불가: 회색 + 잠금 아이콘 -->
            <div class="flex items-center gap-2 text-gray-400">
              <span>🔒</span>
              <span><%= chapter[:title] %></span>
            </div>
            <p class="text-xs text-gray-500 ml-6">
              <% if current_user&.trial_active? %>
                구독하여 더 보기
              <% elsif user_signed_in? %>
                구독 필요
              <% else %>
                로그인 후 보기
              <% end %>
            </p>
          <% end %>
        <% else %>
          <!-- 파일 없음: 회색 + 예정 -->
          <div class="flex items-center gap-2 text-gray-400">
            <span>📝</span>
            <span><%= chapter[:title] %></span>
          </div>
          <p class="text-xs text-gray-500 ml-6">공개 예정</p>
        <% end %>
      </li>
    <% end %>
  </ul>
  
  <!-- Trial 상태 표시 -->
  <% if user_signed_in? && current_user.trial_active? %>
    <div class="mt-6 pt-4 border-t border-gray-300">
      <p class="text-sm font-bold text-blue-600">
        ⏰ Trial: <%= current_user.trial_days_remaining %>일 남음
      </p>
      <p class="text-xs text-gray-600 mt-2">
        <%= link_to "지금 구독하기",
          "#",  # 나중에 pricing_path로
          class: "text-blue-500 hover:underline"
        %>
      </p>
    </div>
  <% end %>
</aside>

<!-- 메인 콘텐츠 -->
<main class="flex-1 p-8 max-w-4xl mx-auto">
  <article class="prose prose-lg max-w-none">
    <%= raw @markdown_html %>
  </article>
</main>
```

---

### Step 7: 권한 없을 때 에러 페이지

에러는 `rescue_from`으로 자동 처리되지만, 사용자 친화적 메시지 추가:

**파일: `app/controllers/application_controller.rb`** (수정)

```ruby
class ApplicationController < ActionController::Base
  include Pundit::Authorization
  
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  
  private
  
  def user_not_authorized
    # 더 자세한 메시지
    case current_user
    when nil
      flash[:alert] = "로그인 후 이용 가능합니다. 7일 무료 Trial을 시작하세요!"
      redirect_to new_user_session_path
    when current_user.trial_active?
      flash[:alert] = "이 문서는 구독자만 볼 수 있습니다. #{current_user.trial_days_remaining}일 내에 구독해주세요."
      redirect_to root_path
    else
      flash[:alert] = "전체 문서를 보려면 구독이 필요합니다."
      redirect_to root_path
    end
  end
end
```

---

### Step 8: Rails 콘솔 테스트

```bash
rails c

# Trial 사용자 생성
user_trial = User.create(
  email: 'trial@example.com',
  password: 'password123',
  role: :user  # 일반 사용자
)

# Admin 생성
user_admin = User.create(
  email: 'admin@example.com',
  password: 'password123',
  role: :admin
)

# 권한 확인
policy_trial = DocPolicy.new(user_trial, { id: "05" })
policy_trial.view?  # true (1-5장 가능)

policy_trial = DocPolicy.new(user_trial, { id: "10" })
policy_trial.view?  # false (6-20장 불가)

policy_admin = DocPolicy.new(user_admin, { id: "20" })
policy_admin.view?  # true (모두 가능)

# Trial 날짜 확인
user_trial.trial_days_remaining  # 7
user_trial.trial_active?  # true
```

---

### Step 9: 브라우저 테스트

```
테스트 시나리오:

1️⃣ 비로그인 (Guest)
   URL: http://localhost:3000/docs/01
   ✅ 보여야 함
   
   URL: http://localhost:3000/docs/05
   ❌ 에러: "로그인 후 이용 가능합니다"

2️⃣ 로그인만 (Trial)
   URL: http://localhost:3000/docs/05
   ✅ 보여야 함
   
   URL: http://localhost:3000/docs/10
   ❌ 에러: "이 문서는 구독자만 볼 수 있습니다"
   
   사이드바:
   ✅ 01-05: 파란색 링크
   🔒 06-20: 회색 + "구독 필요"
   ⏰ "Trial: 7일 남음"

3️⃣ Admin (관리자)
   URL: http://localhost:3000/docs/20
   ✅ 보여야 함 (모든 문서 접근)
```

---

### Step 10: 배포

```bash
# 변경사항 커밋
git add .
git commit -m "feat: Add Pundit authorization with 4-tier role system

- Install Pundit gem and create policies (DocPolicy, DashboardPolicy)
- Add role enum and trial methods to User model
- Implement chapter access control: Guest (1-2), Trial (1-5), Subscriber (1-20), Admin (all)
- Add DocPolicy.view? check in DocsController#show
- Update sidebar to show 🔒 icon for inaccessible chapters
- Display trial days remaining in sidebar
- Handle NotAuthorizedError with user-friendly messages"

# Push (자동 배포)
git push origin main

# Railway 배포 확인
# https://web-production-50f0e.up.railway.app/docs/01 (비로그인)
# https://web-production-50f0e.up.railway.app/docs/08 (로그인 필요)
```

---

## 📌 핵심 메커니즘

### 권한 확인 흐름

```
사용자가 /docs/10 접근
  ↓
DocsController#show
  ↓
authorize @doc, policy_class: DocPolicy
  ↓
DocPolicy.new(current_user, @doc)
  ↓
DocPolicy#view? 실행
  - current_user가 nil? → view_as_guest? 체크 (chapter <= 2)
  - current_user.trial_active? → view_as_trial? 체크 (chapter <= 5)
  - current_user.subscribed? → view_as_subscriber? 체크 (chapter <= 20)
  - current_user.admin? → view_as_admin? 체크 (모두 가능)
  ↓
true면 렌더링, false면 Pundit::NotAuthorizedError
  ↓
rescue_from으로 사용자 친화적 메시지 표시
```

---

## ✅ 완료 후 결과

| 항목 | 상태 |
|------|------|
| Pundit 설치 | ✅ |
| Policy 파일 작성 | ✅ |
| User 모델 메서드 | ✅ |
| DocsController authorize! | ✅ |
| 사이드바 UI (🔒 표시) | ✅ |
| Trial 일수 표시 | ✅ |
| 로컬 테스트 | ✅ |
| Railway 배포 | ✅ |

---

## 🚀 다음 단계

다음 장에서는:
- **09 Payment** - Toss Payments 월간 구독 시스템
- **10 Dashboard** - 사용자 전용 페이지
- **11 Pricing** - 가격 페이지 (구독 CTA)
