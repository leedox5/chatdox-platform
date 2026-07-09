---
title: "Docs Preview - 문서 열람 페이지"
order: 2
revision: 0
status: "ready"
tech: "Rails/Tailwind CSS/Redcarpet"
date: "2026-07-09"
dependency: ["01_landing_page_r1.md"]
---

# 📚 Docs Preview 구현 프롬프트

`docs/curriculum/docs/` 폴더의 마크다운 파일을 렌더링하는 문서 열람 페이지입니다.
좌측 사이드바(목차) + 우측 본문 레이아웃으로 구현합니다.

---

## 🎯 구현 목표

```
/docs                    → 목록 (01~04 챕터 카드)
/docs/01_overview        → 사이드바 + 마크다운 렌더링
/docs/02_rails_basics    → 사이드바 + 마크다운 렌더링
/docs/03_dev_setup       → 사이드바 + 마크다운 렌더링
/docs/04_landing_page    → 사이드바 + 마크다운 렌더링
```

### 레이아웃 구조

```
┌─────────────────────────────────────────────────────┐
│  Header (기존)                                       │
├──────────────┬──────────────────────────────────────┤
│              │                                       │
│  사이드바     │  본문 (Markdown 렌더링)               │
│  (좌측 고정) │                                       │
│              │  # 채독스 전체 구조 이해               │
│  📖 Chapter  │                                       │
│  ─────────── │  ## 이 챕터에서 배우는 것              │
│  ✅ 01 개요  │  ...                                  │
│  02 Rails    │                                       │
│  03 환경설정 │                                       │
│  04 랜딩페이지│                                       │
│              │                                       │
└──────────────┴──────────────────────────────────────┘
```

---

## 1️⃣ Gem 추가

```ruby
# Gemfile
gem "redcarpet"   # Markdown → HTML 렌더링
```

```bash
bundle install
```

---

## 2️⃣ Routes 설정

```ruby
# config/routes.rb
Rails.application.routes.draw do
  root "pages#home"

  # Docs
  get "/docs",      to: "docs#index"
  get "/docs/:id",  to: "docs#show", as: "doc"

  # 기존 dummy 페이지들
  get "/getting-started", to: "pages#getting_started"
  get "/pricing",         to: "pages#pricing"
  get "/community",       to: "pages#community"
  get "/login",           to: "pages#login"
  get "/terms",           to: "pages#terms"
  get "/privacy",         to: "pages#privacy"
end
```

---

## 3️⃣ DocsController

```ruby
# app/controllers/docs_controller.rb
class DocsController < ApplicationController
  DOCS_PATH = Rails.root.join("docs/curriculum/docs")

  # 챕터 목록 정의 (순서 보장)
  CHAPTERS = [
    { id: "01_overview",      title: "채독스 전체 구조 이해",    subtitle: "서비스 아키텍처, 기술 스택, 학습 로드맵" },
    { id: "02_rails_basics",  title: "Ruby on Rails 기초",      subtitle: "Rails 개념, MVC 패턴, 주요 기능" },
    { id: "03_dev_setup",     title: "개발 환경 세팅",            subtitle: "Git, 데이터베이스, 종속성 설치" },
    { id: "04_landing_page",  title: "랜딩페이지 구축",           subtitle: "Tailwind CSS, 반응형 디자인" }
  ].freeze

  def index
    @chapters = CHAPTERS
  end

  def show
    @chapters = CHAPTERS
    @current_id = params[:id]
    @current_chapter = CHAPTERS.find { |c| c[:id] == @current_id }

    # 404 처리
    unless @current_chapter
      render plain: "챕터를 찾을 수 없습니다.", status: :not_found
      return
    end

    # 마크다운 파일 읽기
    file_path = DOCS_PATH.join("#{@current_id}.md")
    unless File.exist?(file_path)
      render plain: "파일을 찾을 수 없습니다: #{@current_id}.md", status: :not_found
      return
    end

    raw_markdown = File.read(file_path)

    # Redcarpet 렌더러 설정
    renderer = Redcarpet::Render::HTML.new(
      hard_wrap: true,
      link_attributes: { target: "_blank" }
    )
    markdown = Redcarpet::Markdown.new(renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      superscript: true
    )

    @content_html = markdown.render(raw_markdown).html_safe
  end
end
```

---

## 4️⃣ Views

### 목록 페이지 (`app/views/docs/index.html.erb`)

```erb
<div class="min-h-screen bg-gray-50">
  <div class="max-w-4xl mx-auto py-16 px-4">

    <!-- 헤더 -->
    <div class="mb-12">
      <div class="text-blue-600 text-sm font-semibold uppercase tracking-wide mb-2">문서</div>
      <h1 class="text-4xl font-bold text-gray-900 mb-4">완전한 커리큘럼</h1>
      <p class="text-lg text-gray-500">기초부터 배포와 운영까지, 실제 서비스 구축 순서대로 구성되어 있습니다.</p>
    </div>

    <!-- 챕터 카드 목록 -->
    <div class="space-y-4">
      <% @chapters.each_with_index do |chapter, index| %>
        <%= link_to doc_path(chapter[:id]),
              class: "block bg-white border border-gray-200 rounded-xl p-6
                      hover:shadow-md hover:border-blue-200 transition-all group" do %>
          <div class="flex items-start gap-4">
            <!-- 번호 -->
            <div class="flex-shrink-0 w-10 h-10 bg-blue-50 rounded-lg flex items-center
                        justify-center text-blue-600 font-bold text-sm group-hover:bg-blue-100">
              <%= sprintf("%02d", index + 1) %>
            </div>
            <!-- 내용 -->
            <div>
              <h2 class="text-lg font-semibold text-gray-900 group-hover:text-blue-600 mb-1">
                <%= chapter[:title] %>
              </h2>
              <p class="text-gray-500 text-sm"><%= chapter[:subtitle] %></p>
            </div>
            <!-- 화살표 -->
            <div class="ml-auto text-gray-300 group-hover:text-blue-400 text-xl">→</div>
          </div>
        <% end %>
      <% end %>
    </div>

    <!-- 예정 챕터 안내 -->
    <div class="mt-8 p-6 bg-blue-50 rounded-xl border border-blue-100">
      <p class="text-blue-700 text-sm font-medium">
        📌 챕터 05~20은 순차적으로 공개됩니다.
      </p>
    </div>

  </div>
</div>
```

### 개별 챕터 페이지 (`app/views/docs/show.html.erb`)

```erb
<div class="flex min-h-screen bg-white">

  <!-- ── 좌측 사이드바 ── -->
  <aside class="w-64 flex-shrink-0 border-r border-gray-200 bg-gray-50 sticky top-0 h-screen overflow-y-auto">
    <div class="p-6">

      <!-- 사이드바 헤더 -->
      <div class="mb-6">
        <%= link_to "← 문서 목록", docs_path,
              class: "text-sm text-gray-500 hover:text-blue-600 mb-3 block" %>
        <h2 class="text-xs font-semibold text-gray-400 uppercase tracking-wider">커리큘럼</h2>
      </div>

      <!-- 챕터 목록 -->
      <nav class="space-y-1">
        <% @chapters.each_with_index do |chapter, index| %>
          <% is_current = chapter[:id] == @current_id %>
          <%= link_to doc_path(chapter[:id]),
                class: "flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-colors #{
                  is_current ?
                    'bg-blue-50 text-blue-700 font-semibold' :
                    'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
                }" do %>
            <span class="flex-shrink-0 w-6 h-6 rounded-md flex items-center justify-center text-xs
                         <%= is_current ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-500' %>">
              <%= sprintf("%02d", index + 1) %>
            </span>
            <span class="leading-tight"><%= chapter[:title] %></span>
          <% end %>
        <% end %>

        <!-- 예정 챕터 -->
        <div class="pt-4 mt-4 border-t border-gray-200">
          <p class="text-xs text-gray-400 px-3">05~20 챕터 공개 예정</p>
        </div>
      </nav>

    </div>
  </aside>

  <!-- ── 우측 본문 ── -->
  <main class="flex-1 overflow-y-auto">
    <div class="max-w-3xl mx-auto py-12 px-8">

      <!-- 챕터 정보 -->
      <div class="mb-8 pb-6 border-b border-gray-100">
        <p class="text-blue-600 text-sm font-semibold uppercase tracking-wide mb-2">
          <%= @current_chapter[:subtitle] %>
        </p>
      </div>

      <!-- Markdown 렌더링 본문 -->
      <div class="prose prose-lg max-w-none">
        <%= @content_html %>
      </div>

      <!-- 이전/다음 네비게이션 -->
      <% current_index = @chapters.index { |c| c[:id] == @current_id } %>
      <div class="flex justify-between mt-16 pt-8 border-t border-gray-100">
        <% if current_index > 0 %>
          <% prev_chapter = @chapters[current_index - 1] %>
          <%= link_to doc_path(prev_chapter[:id]),
                class: "flex items-center gap-2 text-gray-500 hover:text-blue-600 text-sm" do %>
            <span>←</span>
            <span><%= prev_chapter[:title] %></span>
          <% end %>
        <% else %>
          <div></div>
        <% end %>

        <% if current_index < @chapters.length - 1 %>
          <% next_chapter = @chapters[current_index + 1] %>
          <%= link_to doc_path(next_chapter[:id]),
                class: "flex items-center gap-2 text-gray-500 hover:text-blue-600 text-sm" do %>
            <span><%= next_chapter[:title] %></span>
            <span>→</span>
          <% end %>
        <% end %>
      </div>

    </div>
  </main>

</div>
```

---

## 5️⃣ Tailwind Prose 스타일 (Markdown 본문)

Markdown 렌더링 결과에 Typography 스타일 적용:

```bash
# Tailwind Typography 플러그인 설치
npm install -D @tailwindcss/typography
```

```javascript
// tailwind.config.js
module.exports = {
  plugins: [
    require('@tailwindcss/typography'),
  ],
}
```

> **없어도 동작하지만**, `prose` 클래스로 h1~h6, p, code, table 등이 자동 스타일링됩니다.

---

## 6️⃣ Header 링크 업데이트

```erb
<!-- 기존: href="#" 또는 pages#docs -->
<!-- 변경 후: -->
<%= link_to "문서", docs_path, class: "..." %>
```

---

## ✅ 구현 체크리스트

### 준비
- [ ] `gem "redcarpet"` Gemfile 추가
- [ ] `bundle install`
- [ ] `npm install -D @tailwindcss/typography` (선택)

### 파일 생성
- [ ] `app/controllers/docs_controller.rb`
- [ ] `app/views/docs/index.html.erb`
- [ ] `app/views/docs/show.html.erb`
- [ ] `config/routes.rb` 업데이트
- [ ] `tailwind.config.js` 업데이트 (선택)
- [ ] Header의 "문서" 링크를 `docs_path`로 업데이트

### 검증
- [ ] `/docs` 접속 → 챕터 목록 4개 표시
- [ ] 챕터 클릭 → 사이드바 + 본문 표시
- [ ] 현재 챕터 사이드바에서 파란색 하이라이트
- [ ] 이전/다음 챕터 네비게이션 동작
- [ ] 마크다운 헤더(#), 코드블록(``), 표(|) 렌더링 확인
- [ ] 모바일에서 사이드바 처리 확인

---

## 📌 다음 Revision 예고 (R1)

| 기능 | 내용 |
|------|------|
| 모바일 사이드바 | 햄버거 메뉴로 접기/펼치기 |
| 샘플 제한 | 비로그인 → 앞 500자만 공개 |
| 진행 표시 | 읽은 챕터 체크 표시 |
| 검색 | 챕터 내 키워드 검색 |

---

**마지막 업데이트:** 2026-07-09
