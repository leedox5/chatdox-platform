---
title: "Rails Markdown 렌더링 - Redcarpet 가이드"
date: "2026-07-09"
category: "Rails"
difficulty: "중급"
related: ["prompts/02_docs_preview.md", "docs/04_landing_page.md"]
---

# Rails Markdown 렌더링 - Redcarpet 가이드

Markdown을 HTML로 변환할 때 **Redcarpet** gem을 올바르게 사용하는 방법을 배웁니다.

---

## 🎯 이 팁을 읽어야 하는 경우

- Redcarpet이 뭐하는 건지 정확히 알고 싶다
- Markdown 옵션들이 뭐가 뭔지 모르겠다
- XSS 보안이 걱정된다
- 사용자 입력 Markdown은 어떻게 처리할지 궁금하다
- 성능이 중요한 프로젝트다

---

## 📋 Redcarpet이란?

### 개념

```
Markdown (.md 파일)
    ↓ (parse & render)
Redcarpet gem
    ↓
HTML (브라우저가 표시)
```

### 예시

```markdown
# 제목입니다

**굵은 글씨**

```ruby
puts "코드 블록"
```
```

↓ Redcarpet 렌더링 ↓

```html
<h1>제목입니다</h1>
<p><strong>굵은 글씨</strong></p>
<pre><code class="language-ruby">puts "코드 블록"</code></pre>
```

---

## 🔧 설치 & 기본 사용법

### 1️⃣ Gemfile 추가

```ruby
gem "redcarpet"
```

```bash
bundle install
```

### 2️⃣ 컨트롤러에서 사용

```ruby
class DocsController < ApplicationController
  def show
    # 마크다운 읽기
    markdown_text = File.read("path/to/file.md")

    # Redcarpet 렌더러 생성
    renderer = Redcarpet::Render::HTML.new
    markdown = Redcarpet::Markdown.new(renderer)

    # HTML로 변환
    html = markdown.render(markdown_text)
  end
end
```

### 3️⃣ 뷰에서 표시

```erb
<div class="prose">
  <%= @content_html.html_safe %>
</div>
```

> **주의**: `.html_safe`는 Redcarpet이 안전하게 escape 처리했을 때만 사용.

---

## ⚙️ Renderer 옵션

### HTML Renderer 옵션

```ruby
renderer = Redcarpet::Render::HTML.new(
  hard_wrap: true,           # 줄바꿈을 <br>로 변환
  link_attributes: { target: "_blank" },  # 외부 링크 새탭 열기
  filter_html: false,         # HTML 태그 무시 (false=허용)
  prettify: false,            # 코드 블록에 class 추가
  no_images: false,           # 이미지 태그 무시
  no_links: false,            # 링크 태그 무시
  no_styles: false            # 스타일 태그 무시
)
```

### 사용 예시

```ruby
# 안전한 설정 (사용자 입력용)
safe_renderer = Redcarpet::Render::HTML.new(
  filter_html: true,   # HTML 태그 제거
  no_images: true,     # 이미지 비활성
  no_links: false      # 링크만 허용
)

# 자유로운 설정 (관리자 콘텐츠용)
admin_renderer = Redcarpet::Render::HTML.new(
  hard_wrap: true,
  link_attributes: { target: "_blank" }
)
```

---

## 🎨 Markdown 옵션 (Parser)

Markdown **파서** 설정 (Renderer와 별개):

```ruby
markdown = Redcarpet::Markdown.new(renderer,
  autolink: true,                    # URL 자동 링크 (http://...)
  tables: true,                      # 표 지원 (|---|)
  fenced_code_blocks: true,          # 코드 블록 (```lang)
  no_intra_emphasis: false,          # _중간_emphasis 허용
  strikethrough: true,               # ~~취소선~~ 지원
  superscript: true,                 # 2^3 = 8 지원
  highlight: false,                  # 하이라이트 (==텍스트==)
  quote: false                       # 인용 처리
)

html = markdown.render(markdown_text)
```

### 자주 사용하는 조합

```ruby
# 📚 문서용 (모든 기능)
Redcarpet::Markdown.new(renderer,
  autolink: true,
  tables: true,
  fenced_code_blocks: true,
  strikethrough: true,
  superscript: true
)

# 💬 댓글용 (기본 기능만)
Redcarpet::Markdown.new(renderer,
  autolink: true,
  no_intra_emphasis: true  # _word_ 강조 금지
)

# 📝 사용자 입력용 (제한적)
Redcarpet::Markdown.new(renderer,
  autolink: true,
  fenced_code_blocks: false  # 코드 블록 금지
)
```

---

## 🔐 보안: 사용자 입력 처리

### ❌ 위험한 방법

```ruby
# 사용자가 입력한 마크다운 그대로 렌더링
user_input = params[:content]
renderer = Redcarpet::Render::HTML.new
markdown = Redcarpet::Markdown.new(renderer)
html = markdown.render(user_input)
# XSS 취약점! 사용자가 <script> 주입 가능
```

### ✅ 안전한 방법

```ruby
# 방법 1: Redcarpet의 filter_html 옵션
safe_renderer = Redcarpet::Render::HTML.new(
  filter_html: true,      # HTML 태그 모두 제거
  no_images: true,        # 이미지 태그 제거
  no_links: true          # 링크도 제거 (필요시)
)

# 방법 2: sanitize gem (더 세밀한 제어)
gem "rails-html-sanitizer"

html = markdown.render(user_input)
sanitized = sanitize(html, tags: %w(p br strong em a), attributes: %w(href))
```

### 의사 코드

```ruby
class CommentService
  def render_safe(markdown_text)
    # Step 1: Redcarpet (기본 렌더링)
    renderer = Redcarpet::Render::HTML.new(filter_html: true)
    markdown = Redcarpet::Markdown.new(renderer, fenced_code_blocks: true)
    html = markdown.render(markdown_text)

    # Step 2: 추가 정제 (선택)
    sanitize(html, tags: %w(p br strong em ul li ol code pre a))
  end
end
```

---

## 📊 Redcarpet vs 다른 Gem 비교

| Gem | 특징 | 보안 | 속도 | 추천 상황 |
|-----|------|------|------|---------|
| **Redcarpet** | 빠르고, 옵션 풍부 | 수동 처리 필요 | 매우 빠름 | 문서, 블로그 |
| **Kramdown** | GitHub 호환 | 중상 | 느림 | GitHub 일관성 필요시 |
| **CommonMarker** | 최신, 표준 | 중상 | 빠름 | 장기 유지보수 필수 |
| **Pandoc** | 강력, 다양한 포맷 | 좋음 | 느림 | 다양한 형식 필요시 |

→ **간단하고 빠르면**: Redcarpet ✅  
→ **GitHub와 호환**: Kramdown  
→ **장기 유지보수**: CommonMarker

---

## ⚡ 성능 최적화

### 문제: Markdown 렌더링이 느림

```ruby
def show
  markdown_text = File.read("big_file.md")  # 10MB
  renderer = Redcarpet::Render::HTML.new
  markdown = Redcarpet::Markdown.new(renderer, tables: true)
  @html = markdown.render(markdown_text)    # ← 느림!
end
```

### 해결 1️⃣: 캐싱

```ruby
class DocsController < ApplicationController
  def show
    @html = Rails.cache.fetch("doc_#{params[:id]}_html", expires_in: 1.day) do
      markdown_text = File.read("docs/#{params[:id]}.md")
      render_markdown(markdown_text)
    end
  end

  private

  def render_markdown(text)
    renderer = Redcarpet::Render::HTML.new
    markdown = Redcarpet::Markdown.new(renderer)
    markdown.render(text)
  end
end
```

### 해결 2️⃣: 사전 컴파일 (정적 사이트)

```ruby
# Rake 태스크
namespace :docs do
  task compile: :environment do
    Dir.glob("docs/curriculum/docs/*.md") do |file|
      html = render_markdown(File.read(file))
      # HTML 저장해서 필요할 때 불러오기
    end
  end
end
```

### 해결 3️⃣: 옵션 최소화

```ruby
# 느린 옵션들
markdown = Redcarpet::Markdown.new(renderer,
  highlight: true,      # ← 느림, 사용 안 함
  quote: true,          # ← 느림, 사용 안 함
  prettify: true        # ← 느림, CSS 클래스 추가
)

# 빠른 옵션
markdown = Redcarpet::Markdown.new(renderer,
  fenced_code_blocks: true,  # 코드 블록만
  autolink: true             # 자동 링크만
)
```

---

## 🛡️ HTML Escape 이해하기

### 문제

```markdown
# 제목

<script>alert('XSS')</script>
```

### 기본 동작

```ruby
renderer = Redcarpet::Render::HTML.new()  # filter_html 기본값 = false
html = markdown.render(text)
# 결과:
# <h1>제목</h1>
# <p>&lt;script&gt;alert('XSS')&lt;/script&gt;</p>  ← escape됨
```

> Redcarpet은 **기본적으로 HTML escape** 처리합니다!

### 명시적 무시

```ruby
renderer = Redcarpet::Render::HTML.new(filter_html: true)
# <script> 태그를 모두 제거
```

---

## 💡 실전 팁

### Tip 1: Helper 메서드로 감싸기

```ruby
# app/helpers/docs_helper.rb
module DocsHelper
  def render_markdown(text)
    renderer = Redcarpet::Render::HTML.new(hard_wrap: true)
    markdown = Redcarpet::Markdown.new(renderer,
      fenced_code_blocks: true,
      autolink: true,
      tables: true
    )
    markdown.render(text).html_safe
  end
end

# 뷰에서
<%= render_markdown(@markdown_text) %>
```

### Tip 2: 커스텀 Renderer (고급)

```ruby
class CustomRenderer < Redcarpet::Render::HTML
  def header(text, level)
    %(<h#{level} class="text-#{3+level}xl font-bold">#{text}</h#{level}>)
  end

  def codespan(code)
    %(<code class="bg-gray-100 px-1 rounded">#{code}</code>)
  end
end

renderer = CustomRenderer.new
markdown = Redcarpet::Markdown.new(renderer)
```

### Tip 3: 문서별 다른 설정

```ruby
# 관리자 문서
def admin_render(text)
  # 모든 옵션 활성화
end

# 사용자 댓글
def comment_render(text)
  # 제한적 옵션
end

# 공개 문서
def public_render(text)
  # 중간 수준
end
```

### Tip 4: 뷰에서 `sanitize()`로 한 번 더 걸러낼 때 표가 사라지는 경우 (실전 사례)

`tables: true`도 켰고 `@tailwindcss/typography` 플러그인도 붙였는데 `<table>`이 여전히 텍스트 뭉치로 보인다면, 원인이 Redcarpet이 아니라 **뷰에서 한 번 더 걸어둔 `sanitize()`**일 수 있다.

```erb
<!-- 문제: Redcarpet이 만든 안전한 HTML을 뷰에서 다시 sanitize -->
<%= sanitize(@content_html) %>
```

Rails의 `sanitize` 헬퍼는 기본 허용 태그 목록(`Rails::Html::SafeListSanitizer`)에 `table`/`thead`/`tbody`/`tr`/`th`/`td`가 **포함되어 있지 않다.** Redcarpet이 표를 정상적으로 `<table>`로 렌더링해도, 이 기본 허용 목록으로 다시 걸러지는 순간 표 태그만 통째로 제거되고 텍스트만 남는다 — 그런데 `**볼드**` 같은 인라인 태그(`<strong>`)는 기본 허용 목록에 있어서 살아있으니, "일부만 스타일이 깨진 것"처럼 보여 원인 파악이 더 헷갈린다.

```ruby
# 해결: 허용 태그에 표 관련 태그를 명시적으로 추가
<%= sanitize(@content_html, tags: Rails::Html::SafeListSanitizer.allowed_tags + %w(table thead tbody tr th td)) %>
```

**체크 순서:** `<table>` 자체가 안 보이면 ①`tables: true` 확인 → ②뷰에 `sanitize()` 호출이 있는지 확인하고 있다면 허용 태그에 표 관련 태그 추가 → ③그래도 스타일(테두리/간격)만 없다면 Typography 플러그인 확인, 순서로 좁혀나가면 된다.

---

## 🔍 자주 묻는 질문

**Q: `.html_safe`를 언제 쓸까?**  
A: Redcarpet이 안전하게 escape 처리한 HTML만. 사용자 입력은 `filter_html: true` 후 사용.

**Q: 마크다운 렌더링이 느린데?**  
A: 캐싱 추가. Rails.cache.fetch로 1일 단위 캐싱하면 대부분 해결.

**Q: 테이블 지원 안 하나?**  
A: `tables: true` 옵션 추가하고, Markdown에 `|---|` 형식 사용.

**Q: `tables: true`도, Typography 플러그인도 붙였는데 표가 여전히 안 나온다?**  
A: 뷰에서 `sanitize()`를 한 번 더 걸고 있는지 확인. 기본 허용 태그 목록엔 `table`류가 없어서 그대로 통과시키면 표만 제거된다. 위 "Tip 4: sanitize()로 한 번 더 걸러낼 때 표가 사라지는 경우" 참고 (service-desk REQ 0005 실제 사례).

**Q: 하이라이트된 코드 블록?**  
A: Redcarpet은 `<code class="language-ruby">` 까지만. 스타일링은 CSS (Tailwind) 또는 highlight.js 같은 라이브러리 사용.

**Q: 이미지 자동 로딩 방지?**  
A: `no_images: true` 옵션. 또는 URL 화이트리스트 검증.

---

## 📚 관련 문서

- [prompts/02_docs_preview.md](../prompts/02_docs_preview.md) — Redcarpet 실제 사용
- [docs/04_landing_page.md](../docs/04_landing_page.md) — 마크다운 서식 예시

---

## 🎯 핵심 정리

```
Redcarpet은 "Markdown → HTML" 변환 도구

Key Points:

1. 렌더러 옵션 (Renderer)
   - filter_html: 사용자 입력 안전화
   - hard_wrap: 줄바꿈 처리

2. 파서 옵션 (Parser)
   - tables: true → 표 지원
   - fenced_code_blocks: true → ``` 지원

3. 보안
   - 기본: HTML escape (안전)
   - 사용자 입력: filter_html: true 필수

4. 성능
   - 렌더 결과 캐싱
   - 옵션 최소화

"기본값이 안전하다"는 것 기억하기!
```

---

**마지막 업데이트:** 2026-07-12
