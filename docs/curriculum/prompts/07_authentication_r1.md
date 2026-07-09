---
title: "07 Authentication R1: Devise 설치 & 회원가입/로그인 UI"
description: "Platform에 Devise 인증 시스템 구현 (회원가입, 로그인, 세션)"
version: "R1"
---

# 07 Authentication R1: Devise 설치 & 회원가입/로그인 UI

## 🎯 목표

Platform 프로젝트에 완전한 인증 시스템 구현:

1. ✅ Devise 젬 설치 & User 모델 생성
2. ✅ 회원가입/로그인 UI (Tailwind CSS)
3. ✅ 레이아웃 헤더에 인증 상태 표시
4. ✅ 테스트 & 배포

---

## 📋 필수 단계

### Step 1: Devise 설치

```bash
# Platform 폴더에서
cd ~/chatdox-platform  # or d:\dev\chatdox-platform (Windows)

# Devise 젬 추가
bundle add devise

# Devise 초기화
rails generate devise:install

# User 모델 생성
rails generate devise User

# 마이그레이션 실행
rails db:migrate
```

**확인:**

```bash
# 파일 생성 확인
ls app/models/user.rb
ls config/initializers/devise.rb
ls app/views/devise/

# 라우트 확인
rails routes | grep devise
```

---

### Step 2: Devise 뷰 커스터마이징

```bash
# Devise 기본 뷰를 프로젝트로 복사 (커스터마이징용)
rails generate devise:views users
```

**생성되는 파일:**

```
app/views/devise/
├── registrations/
│   ├── edit.html.erb
│   ├── new.html.erb
│   └── _form.html.erb
├── sessions/
│   └── new.html.erb
└── passwords/
    ├── edit.html.erb
    └── new.html.erb
```

---

### Step 3: 회원가입 UI 스타일링

**파일: `app/views/devise/registrations/new.html.erb`**

```erb
<div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
  <div class="bg-white rounded-lg shadow-lg p-8 w-full max-w-md">
    <h1 class="text-3xl font-bold text-center mb-6 text-gray-800">
      회원가입
    </h1>

    <%= form_with(model: resource, local: true) do |form| %>
      <% if resource.errors.any? %>
        <div class="mb-4 p-4 bg-red-50 border border-red-200 rounded">
          <h2 class="text-red-800 font-bold mb-2">
            <%= resource.errors.count %>개 오류 발생:
          </h2>
          <ul class="list-disc list-inside text-red-700">
            <% resource.errors.full_messages.each do |message| %>
              <li><%= message %></li>
            <% end %>
          </ul>
        </div>
      <% end %>

      <!-- 이메일 입력 -->
      <div class="mb-4">
        <label class="block text-gray-700 font-bold mb-2">
          이메일
        </label>
        <%= form.email_field :email,
          class: "w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-blue-500",
          autofocus: true,
          autocomplete: "email",
          required: true
        %>
      </div>

      <!-- 비밀번호 입력 -->
      <div class="mb-4">
        <label class="block text-gray-700 font-bold mb-2">
          비밀번호 (6자 이상)
        </label>
        <%= form.password_field :password,
          class: "w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-blue-500",
          autocomplete: "new-password",
          required: true
        %>
      </div>

      <!-- 비밀번호 확인 -->
      <div class="mb-6">
        <label class="block text-gray-700 font-bold mb-2">
          비밀번호 확인
        </label>
        <%= form.password_field :password_confirmation,
          class: "w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-blue-500",
          autocomplete: "new-password",
          required: true
        %>
      </div>

      <!-- 회원가입 버튼 -->
      <div class="mb-4">
        <%= form.submit "회원가입",
          class: "w-full bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded-lg transition"
        %>
      </div>
    <% end %>

    <!-- 로그인 링크 -->
    <p class="text-center text-gray-600 text-sm">
      이미 계정이 있나요?
      <%= link_to "로그인", new_user_session_path, class: "text-blue-500 hover:underline font-bold" %>
    </p>
  </div>
</div>
```

---

### Step 4: 로그인 UI 스타일링

**파일: `app/views/devise/sessions/new.html.erb`**

```erb
<div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
  <div class="bg-white rounded-lg shadow-lg p-8 w-full max-w-md">
    <h1 class="text-3xl font-bold text-center mb-6 text-gray-800">
      로그인
    </h1>

    <%= form_with(model: resource, local: true, url: user_session_path) do |form| %>
      <!-- 에러 메시지 -->
      <% if resource.errors.any? %>
        <div class="mb-4 p-4 bg-red-50 border border-red-200 rounded">
          <p class="text-red-800">
            <strong>로그인 실패:</strong>
            이메일 또는 비밀번호가 올바르지 않습니다.
          </p>
        </div>
      <% end %>

      <!-- 이메일 입력 -->
      <div class="mb-4">
        <label class="block text-gray-700 font-bold mb-2">
          이메일
        </label>
        <%= form.email_field :email,
          class: "w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-blue-500",
          autofocus: true,
          required: true
        %>
      </div>

      <!-- 비밀번호 입력 -->
      <div class="mb-4">
        <label class="block text-gray-700 font-bold mb-2">
          비밀번호
        </label>
        <%= form.password_field :password,
          class: "w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-blue-500",
          required: true
        %>
      </div>

      <!-- "로그인 상태 유지" 체크박스 -->
      <div class="mb-6">
        <%= form.check_box :remember_me, class: "mr-2" %>
        <label class="text-gray-600">
          로그인 상태 유지
        </label>
      </div>

      <!-- 로그인 버튼 -->
      <div class="mb-4">
        <%= form.submit "로그인",
          class: "w-full bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded-lg transition"
        %>
      </div>
    <% end %>

    <!-- 회원가입/비밀번호 리셋 링크 -->
    <p class="text-center text-gray-600 text-sm mb-2">
      계정이 없나요?
      <%= link_to "회원가입", new_user_registration_path, class: "text-blue-500 hover:underline font-bold" %>
    </p>
    <p class="text-center text-gray-600 text-sm">
      비밀번호를 잊었나요?
      <%= link_to "비밀번호 리셋", new_user_password_path, class: "text-blue-500 hover:underline font-bold" %>
    </p>
  </div>
</div>
```

---

### Step 5: 레이아웃 헤더 업데이트

**파일: `app/views/layouts/application.html.erb`**

헤더 부분을 다음과 같이 수정:

```erb
<!-- 기존 헤더에 인증 섹션 추가 -->

<header class="bg-white shadow">
  <div class="max-w-7xl mx-auto px-4 py-4">
    <div class="flex justify-between items-center">
      <!-- 로고 -->
      <div>
        <h1 class="text-2xl font-bold">
          <%= link_to "채독스", root_path, class: "text-gray-800 hover:text-blue-500" %>
        </h1>
      </div>

      <!-- 네비게이션 -->
      <nav class="flex items-center gap-6">
        <!-- 메뉴 -->
        <div class="hidden md:flex gap-6">
          <%= link_to "시작", root_path, class: "text-gray-600 hover:text-blue-500" %>
          <%= link_to "가격", "#", class: "text-gray-600 hover:text-blue-500" %>
          <%= link_to "문서", docs_path, class: "text-gray-600 hover:text-blue-500" %>
          <%= link_to "커뮤니티", "#", class: "text-gray-600 hover:text-blue-500" %>
        </div>

        <!-- 인증 상태 -->
        <div class="flex items-center gap-4">
          <% if user_signed_in? %>
            <!-- 로그인한 경우 -->
            <span class="text-gray-600">
              <%= current_user.email %>
            </span>
            <%= link_to "로그아웃",
              destroy_user_session_path,
              method: :delete,
              class: "px-4 py-2 bg-red-500 hover:bg-red-600 text-white rounded-lg transition"
            %>
          <% else %>
            <!-- 로그인 전 -->
            <%= link_to "로그인",
              new_user_session_path,
              class: "px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white rounded-lg transition"
            %>
            <%= link_to "회원가입",
              new_user_registration_path,
              class: "px-4 py-2 bg-green-500 hover:bg-green-600 text-white rounded-lg transition"
            %>
          <% end %>
        </div>
      </nav>
    </div>
  </div>
</header>
```

---

### Step 6: 보안 설정

**파일: `app/controllers/application_controller.rb`**

```ruby
class ApplicationController < ActionController::Base
  # 선택: 모든 페이지에서 로그인 필수
  # before_action :authenticate_user!
  
  # 또는 특정 컨트롤러에서만:
  # (다음 장에서 다룬다)
end
```

**파일: `config/routes.rb`** (확인)

```ruby
Rails.application.routes.draw do
  devise_for :users  # Devise가 자동 추가
  
  root "pages#home"
  get "/docs", to: "docs#index"
  get "/docs/:id", to: "docs#show", as: "doc"
end
```

---

### Step 7: 테스트

```bash
# 1단계: 서버 시작
rails s

# 2단계: 브라우저에서 테스트
# http://localhost:3000/users/sign_up  (회원가입)
# http://localhost:3000/users/sign_in  (로그인)

# 3단계: 테스트 계정 생성
# test@example.com / password123
```

**테스트 체크리스트:**

```
회원가입 테스트:
  ☐ /users/sign_up 접속
  ☐ test@example.com / password123 입력
  ☐ 회원가입 버튼 클릭
  ☐ 자동으로 로그인됨 (헤더에 이메일 표시)
  ☐ 홈페이지로 리다이렉트

로그아웃 테스트:
  ☐ 헤더의 "로그아웃" 버튼 클릭
  ☐ 로그인/회원가입 버튼 다시 나타남

로그인 테스트:
  ☐ /users/sign_in 접속
  ☐ test@example.com / password123 입력
  ☐ 로그인 버튼 클릭
  ☐ 헤더에 이메일 표시됨

오류 메시지 테스트:
  ☐ 잘못된 비밀번호로 로그인 시도
  ☐ "이메일 또는 비밀번호가 올바르지 않습니다" 메시지 표시
```

---

### Step 8: 배포

```bash
# 변경사항 커밋
git add .
git commit -m "feat: Add Devise authentication with UI

- Install Devise gem and generate User model
- Create styled signup/login pages (Tailwind CSS)
- Update layout header with auth status
- Add current_user display and logout functionality"

# Push (자동 배포)
git push origin main

# Railway 배포 확인 (약 2~3분)
# https://web-production-50f0e.up.railway.app/users/sign_up
```

---

## 📌 핵심 코드 스니펫

### 현재 사용자 확인

```ruby
# 컨트롤러에서
current_user        # 로그인한 사용자 객체
user_signed_in?     # boolean (로그인 여부)
```

### 뷰에서 조건부 렌더링

```erb
<% if user_signed_in? %>
  <p>로그인 상태: <%= current_user.email %></p>
<% else %>
  <p>로그인하세요.</p>
<% end %>
```

### 라우트 보호

```ruby
# 특정 액션만 보호
before_action :authenticate_user!, only: [:edit, :destroy]

# 모든 액션 보호
before_action :authenticate_user!
```

---

## ✅ 완료 후 결과

| 항목 | 상태 |
|------|------|
| Devise 설치 | ✅ |
| User 모델 생성 | ✅ |
| 회원가입 UI | ✅ |
| 로그인 UI | ✅ |
| 헤더 인증 표시 | ✅ |
| 로컬 테스트 | ✅ |
| Railway 배포 | ✅ |

---

## 🚀 다음 단계

다음 장에서는:
- **08 Authorization** - 역할 기반 접근 제어 (Pundit)
- **09 Payment** - Stripe 결제 시스템
- **10 Dashboard** - 사용자 전용 페이지
