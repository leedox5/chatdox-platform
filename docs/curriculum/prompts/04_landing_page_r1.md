---
title: "Landing Page - Revision 1"
order: 1
revision: 1
base: "01_landing_page.md"
status: "ready"
tech: "Rails/Tailwind CSS"
date: "2026-07-09"
---

# 🔄 Landing Page Revision 1

`01_landing_page.md` 초안 구현 완료 후 **1차 수정 프롬프트**입니다.

---

## 📸 현재 상태 (Draft 완료)

- Hero 섹션: 가운데 정렬 완료 ✅
- 8개 섹션 전체 구현 완료 ✅
- Tailwind CSS 스타일링 완료 ✅

---

## ✏️ 수정 사항

### 1️⃣ Header 네비게이션 링크 → Dummy 페이지 연결

현재 모든 링크가 `href="#"` 상태입니다.
각 링크를 **간단한 안내 텍스트가 있는 dummy 페이지**로 연결해 주세요.

#### 대상 링크

| 링크명 | 경로 | Dummy 페이지 내용 |
|-------|------|-----------------|
| **시작** | `/getting-started` | "시작하기 페이지입니다. 준비 중입니다." |
| **가격** | `/pricing` | "가격 페이지입니다. 준비 중입니다." |
| **문서** | `/docs` | "문서 페이지입니다. 준비 중입니다." |
| **커뮤니티** | `/community` | "커뮤니티 페이지입니다. 준비 중입니다." |
| **로그인** | `/login` | "로그인 페이지입니다. 준비 중입니다." |

#### 구현 방법

```ruby
# config/routes.rb
Rails.application.routes.draw do
  root "pages#home"

  # Dummy 페이지
  get "/getting-started", to: "pages#getting_started"
  get "/pricing",         to: "pages#pricing"
  get "/docs",            to: "pages#docs"
  get "/community",       to: "pages#community"
  get "/login",           to: "pages#login"
end
```

```ruby
# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  def home; end
  def getting_started; end
  def pricing; end
  def docs; end
  def community; end
  def login; end
end
```

각 뷰 파일 (`app/views/pages/*.html.erb`):

```erb
<!-- app/views/pages/getting_started.html.erb -->
<div class="min-h-screen flex items-center justify-center bg-gray-50">
  <div class="text-center max-w-md px-4">
    <div class="text-blue-600 text-sm font-semibold uppercase tracking-wide mb-2">시작하기</div>
    <h1 class="text-3xl font-bold text-gray-900 mb-4">준비 중입니다</h1>
    <p class="text-gray-500 mb-8">이 페이지는 현재 개발 중입니다. 곧 만나보세요!</p>
    <%= link_to "← 홈으로 돌아가기", root_path,
          class: "text-blue-600 hover:underline font-medium" %>
  </div>
</div>
```

> 같은 구조로 `/pricing`, `/docs`, `/community`, `/login` 각각 페이지명만 바꿔서 생성.

---

### 2️⃣ Hero 섹션 CTA 버튼 연결

| 버튼 | 현재 | 연결 |
|------|------|------|
| **7일 무료 체험 시작** | `#` | `/getting-started` |
| **자세히 보기** | `#` | `/pricing` |

---

### 3️⃣ Footer 링크 연결

| 링크 | 경로 |
|------|------|
| **이용 약관** | `/terms` |
| **개인정보 처리 방침** | `/privacy` |

```ruby
# routes.rb 추가
get "/terms",   to: "pages#terms"
get "/privacy", to: "pages#privacy"
```

---

## 🎨 Dummy 페이지 공통 디자인 가이드

모든 dummy 페이지는 **동일한 구조**를 사용합니다:

```erb
<!-- app/views/pages/[page_name].html.erb -->
<div class="min-h-screen flex items-center justify-center bg-gray-50">
  <div class="text-center max-w-md px-4">
    <!-- 페이지 레이블 -->
    <div class="text-blue-600 text-sm font-semibold uppercase tracking-wide mb-2">
      [페이지명]
    </div>

    <!-- 제목 -->
    <h1 class="text-3xl font-bold text-gray-900 mb-4">준비 중입니다</h1>

    <!-- 안내 -->
    <p class="text-gray-500 mb-8">이 페이지는 현재 개발 중입니다. 곧 만나보세요!</p>

    <!-- 홈으로 -->
    <%= link_to "← 홈으로 돌아가기", root_path,
          class: "text-blue-600 hover:underline font-medium" %>
  </div>
</div>
```

---

## ✅ 구현 체크리스트

### 라우팅
- [ ] `config/routes.rb`에 7개 경로 추가
- [ ] `bin/rails routes` 확인

### 컨트롤러
- [ ] `pages_controller.rb`에 7개 액션 추가

### 뷰 파일
- [ ] `getting_started.html.erb`
- [ ] `pricing.html.erb`
- [ ] `docs.html.erb`
- [ ] `community.html.erb`
- [ ] `login.html.erb`
- [ ] `terms.html.erb`
- [ ] `privacy.html.erb`

### 링크 업데이트
- [ ] Header 네비게이션 링크 5개 실제 경로로 변경
- [ ] Hero CTA 버튼 2개 연결
- [ ] Footer 링크 2개 연결

### 검증
- [ ] 모든 링크 클릭 시 해당 페이지로 이동
- [ ] 각 dummy 페이지에서 "홈으로 돌아가기" 동작
- [ ] `bin/rails server` 에러 없음

---

## 📌 다음 Revision 예고 (R2)

| 페이지 | R2 수정 내용 |
|--------|------------|
| `/login` | Devise 실제 로그인 폼으로 교체 |
| `/pricing` | 실제 가격 섹션으로 교체 |
| `/docs` | 커리큘럼 문서 목록으로 교체 |

---

**마지막 업데이트:** 2026-07-09
