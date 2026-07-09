---
title: "Docs Preview R1 - 전체 20챕터 사이드바"
order: 2
revision: 1
status: "ready"
tech: "Rails/Tailwind CSS/Redcarpet"
date: "2026-07-09"
dependency: ["02_docs_preview.md"]
---

# 📚 Docs Preview R1 구현 프롬프트

R0에서 구현한 docs 뷰어를 개선합니다.
**핵심 변경:** 사이드바에 20개 챕터 전체 목록을 표시하고,
파일 존재 여부를 자동 체크하여 링크/공개예정을 구분합니다.

---

## 🎯 R1 목표

```
R0: 존재하는 챕터(4개)만 사이드바에 표시
R1: 20개 챕터 전체 목록 + 파일 없으면 "공개 예정"
```

### 동작 방식

```
md 파일 존재 → ✅ 파란 링크 (클릭 가능)
md 파일 없음 → 🔒 회색 텍스트 "공개 예정"

새 챕터 추가 시:
  docs/curriculum/docs/05_*.md 파일 추가
  → 자동으로 사이드바 링크 활성화 (코드 수정 없음!)
```

---

## 1️⃣ DocsController 수정

```ruby
# app/controllers/docs_controller.rb
class DocsController < ApplicationController
  DOCS_PATH = Rails.root.join("docs/curriculum/docs")

  # 전체 20챕터 목록 (순서 보장)
  CHAPTERS = [
    { id: "01", slug: "01_overview",        title: "채독스 전체 구조 이해" },
    { id: "02", slug: "02_rails_basics",    title: "Ruby on Rails 기초" },
    { id: "03", slug: "03_dev_setup",       title: "개발 환경 세팅" },
    { id: "04", slug: "04_landing_page",    title: "랜딩페이지 구축" },
    { id: "05", slug: "05_project_structure", title: "프로젝트 구조 설계" },
    { id: "06", slug: "06_database",        title: "Database & Migrations" },
    { id: "07", slug: "07_authentication",  title: "Authentication (Devise)" },
    { id: "08", slug: "08_authorization",   title: "Authorization & 권한 관리" },
    { id: "09", slug: "09_payment",         title: "Payment (Toss Payments)" },
    { id: "10", slug: "10_dashboard",       title: "사용자 대시보드" },
    { id: "11", slug: "11_admin",           title: "관리자 대시보드" },
    { id: "12", slug: "12_email",           title: "Email & 알림" },
    { id: "13", slug: "13_file_upload",     title: "파일 업로드 (Active Storage)" },
    { id: "14", slug: "14_api",             title: "API 설계 & JSON" },
    { id: "15", slug: "15_testing",         title: "테스트 (RSpec)" },
    { id: "16", slug: "16_performance",     title: "성능 최적화 & 캐싱" },
    { id: "17", slug: "17_security",        title: "보안 & OWASP" },
    { id: "18", slug: "18_deployment",      title: "배포 (Railway / Render)" },
    { id: "19", slug: "19_monitoring",      title: "모니터링 & 에러 추적" },
    { id: "20", slug: "20_launch",          title: "런칭 & 운영" },
  ].freeze

  def index
    @chapters = chapters_with_availability
  end

  def show
    @chapters = chapters_with_availability
    @current_id = params[:id]
    @current_chapter = CHAPTERS.find { |c| c[:id] == @current_id }

    unless @current_chapter
      render plain: "챕터를 찾을 수 없습니다.", status: :not_found
      return
    end

    # 파일 찾기 (slug 기반)
    file_path = DOCS_PATH.join("#{@current_chapter[:slug]}.md")
    unless File.exist?(file_path)
      render plain: "아직 공개되지 않은 챕터입니다.", status: :not_found
      return
    end

    raw_markdown = File.read(file_path)
    @content_html = render_markdown(raw_markdown)
  end

  private

  def chapters_with_availability
    CHAPTERS.map do |ch|
      file = DOCS_PATH.join("#{ch[:slug]}.md")
      ch.merge(available: File.exist?(file))
    end
  end

  def render_markdown(text)
    renderer = Redcarpet::Render::HTML.new(
      hard_wrap: true,
      link_attributes: { target: "_blank" }
    )
    markdown = Redcarpet::Markdown.new(renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true
    )
    markdown.render(text).html_safe
  end
end
```

---

## 2️⃣ 사이드바 수정 (`show.html.erb`)

```erb
<!-- 사이드바 챕터 목록 부분만 교체 -->
<nav class="space-y-1">
  <% @chapters.each do |chapter| %>
    <% is_current = chapter[:id] == @current_id %>

    <% if chapter[:available] %>
      <!-- 파일 있음 → 파란 링크 -->
      <%= link_to doc_path(chapter[:id]),
            class: "flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-colors #{
              is_current ?
                'bg-blue-50 text-blue-700 font-semibold' :
                'text-gray-600 hover:bg-gray-100'
            }" do %>
        <span class="flex-shrink-0 w-6 h-6 rounded-md flex items-center justify-center text-xs
                     <%= is_current ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-500' %>">
          <%= chapter[:id] %>
        </span>
        <span class="leading-tight"><%= chapter[:title] %></span>
      <% end %>

    <% else %>
      <!-- 파일 없음 → 회색 비활성 -->
      <div class="flex items-center gap-3 px-3 py-2 rounded-lg text-sm cursor-not-allowed opacity-50">
        <span class="flex-shrink-0 w-6 h-6 rounded-md bg-gray-100 text-gray-400
                     flex items-center justify-center text-xs">
          <%= chapter[:id] %>
        </span>
        <span class="leading-tight text-gray-400"><%= chapter[:title] %></span>
        <span class="ml-auto text-xs text-gray-300">예정</span>
      </div>
    <% end %>

  <% end %>
</nav>
```

---

## 3️⃣ index 페이지 수정 (`index.html.erb`)

```erb
<!-- index 카드 목록 - 파일 있는 것만 진한색, 없는 것은 흐리게 -->
<% @chapters.each do |chapter| %>
  <% if chapter[:available] %>
    <%= link_to doc_path(chapter[:id]),
          class: "block bg-white border rounded-xl p-5 hover:shadow-md transition-all group" do %>
      <div class="flex items-center gap-3">
        <span class="w-8 h-8 bg-blue-50 rounded-lg flex items-center justify-center
                     text-blue-600 font-bold text-sm group-hover:bg-blue-100">
          <%= chapter[:id] %>
        </span>
        <span class="font-medium text-gray-900 group-hover:text-blue-600">
          <%= chapter[:title] %>
        </span>
        <span class="ml-auto text-gray-300 group-hover:text-blue-400">→</span>
      </div>
    <% end %>

  <% else %>
    <div class="block bg-gray-50 border border-gray-100 rounded-xl p-5 opacity-50 cursor-not-allowed">
      <div class="flex items-center gap-3">
        <span class="w-8 h-8 bg-gray-100 rounded-lg flex items-center justify-center
                     text-gray-400 font-bold text-sm">
          <%= chapter[:id] %>
        </span>
        <span class="font-medium text-gray-400"><%= chapter[:title] %></span>
        <span class="ml-auto text-xs text-gray-300">공개 예정</span>
      </div>
    </div>
  <% end %>
<% end %>
```

---

## ✅ 구현 체크리스트

### 수정 파일
- [ ] `app/controllers/docs_controller.rb` - CHAPTERS 20개로 확장, `chapters_with_availability` 메서드 추가
- [ ] `app/views/docs/show.html.erb` - 사이드바 available 조건 분기
- [ ] `app/views/docs/index.html.erb` - 카드 available 조건 분기

### 검증
- [ ] `/docs` → 5개 파란 카드 + 15개 흐린 카드 표시
- [ ] `/docs/01` ~ `/docs/05` → 정상 렌더링
- [ ] `/docs/06` → 404 또는 "공개 예정" 메시지
- [ ] 새 md 파일 추가 후 자동 링크 활성화 확인
- [ ] 사이드바 현재 챕터 파란 하이라이트

---

## 📌 새 챕터 추가 방법

```bash
# curriculum 저장소에서
# 1. docs/06_database.md 작성

# 2. platform에서 subtree pull
git subtree pull --prefix=docs/curriculum curriculum-remote main --squash

# 3. 자동으로 사이드바 활성화됨! (코드 수정 없음)
```

---

**마지막 업데이트:** 2026-07-09
