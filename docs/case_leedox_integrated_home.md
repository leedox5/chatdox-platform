# 심화 사례: 단일 상품 홈을 LEEDOX 통합 홈으로 확장하기

> 4장에서 만든 단일 상품 랜딩페이지를 실제 운영 과정에서 상위 브랜드 홈으로 확장한 사례입니다. Platform Agent가 전달한 최종 구현 근거를 기준으로 합니다.

---

## 이 사례에서 배우는 것

- 기존 페이지를 없애지 않고 역할에 맞는 경로로 보존하기
- View와 partial 조합으로 페이지 책임 나누기
- 인증 Header를 데스크톱과 모바일에서 유지하기
- Tailwind 반응형 설계와 한국어 줄바꿈 검증하기
- 통합 테스트와 실제 브라우저 검증 구분하기

## 1. Why — 왜 홈을 나누었나

처음의 `/`는 Chatdox 하나를 소개했습니다. LEEDOX 아래에 Chatdox와 Claudox가 놓이면서 루트 페이지의 책임도 달라졌습니다.

| 경로 | 역할 |
|---|---|
| `/` | LEEDOX와 두 상품을 소개하고 선택을 돕는 상위 브랜드 홈 |
| `/chatdox` | 기존 Chatdox 콘텐츠를 보존한 상품 페이지 |
| `/claudox` | 기존 Markdown 문서 뷰어 |

기존 콘텐츠를 새 홈으로 덮어쓰지 않았습니다. 통합 홈은 선택을 돕고 상품별 경로는 각 콘텐츠를 이어서 제공하도록 책임을 분리했습니다.

## 2. How — 경로와 렌더링 책임 분리

```ruby
# config/routes.rb
root "pages#home"
get "/chatdox", to: "pages#chatdox", as: :chatdox
get "/claudox", to: "claudox#index", as: :claudox
get "/claudox/:id", to: "claudox#show", as: :claudox_chapter
```

Controller는 데이터 조회를 추가하지 않았습니다. 두 action의 차이는 View가 조합하는 partial입니다.

```ruby
class PagesController < ApplicationController
  def home
    # Static landing page: no database query required.
  end

  def chatdox
    # Preserve the original Chatdox landing content as a dedicated product page.
  end
end
```

통합 홈은 새로운 partial을 순서대로 조합합니다.

```erb
<% content_for :title, "LEEDOX | AI 협업을 결과물로" %>
<div class="min-h-screen">
  <%= render "shared/header" %>
  <main>
    <%= render "leedox_home/hero" %>
    <%= render "leedox_home/problems" %>
    <%= render "leedox_home/products" %>
    <%= render "leedox_home/proof" %>
    <%= render "leedox_home/guide" %>
    <%= render "leedox_home/about" %>
    <%= render "leedox_home/faq" %>
    <%= render "leedox_home/cta" %>
  </main>
  <%= render "shared/footer" %>
</div>
```

`/chatdox`는 기존 `landing/*` partial을 다시 조합합니다. 복사하지 않고 렌더링 진입점만 분리했습니다.

> 현재 프로젝트에서는 Header와 Footer를 layout이 자동 삽입하지 않습니다. 각 top-level View가 직접 렌더링해야 합니다. 이것은 현재 코드의 구조이지 Rails의 유일한 권장 방식은 아닙니다.

## 3. Header의 인증과 모바일 메뉴

Header는 Devise의 `user_signed_in?`와 `current_user`를 사용합니다. 비로그인 사용자에게 로그인·회원가입을, 로그인 사용자에게 이메일과 Turbo DELETE 방식의 로그아웃을 보여줍니다. 역할별 링크는 `NavigationHelper#primary_navigation_items`가 반환하며 데스크톱과 모바일이 같은 목록을 사용합니다.

모바일 메뉴는 별도 JavaScript controller 대신 네이티브 `<details>`와 `<summary>`를 사용합니다.

```erb
<details class="group relative md:hidden">
  <summary aria-label="메뉴 열기">☰</summary>
  <nav aria-label="모바일 내비게이션">
    <% primary_navigation_items.each do |label, path| %>
      <%= link_to label, path %>
    <% end %>
  </nav>
</details>
```

JavaScript 없이 키보드로 열고 닫을 수 있지만, 바깥 영역 클릭으로 닫기나 열린 상태에 따른 `aria-label` 변경 같은 세밀한 제어는 제공하지 않습니다.

## 4. partial을 작은 책임으로 나누기

| partial | 책임 |
|---|---|
| `hero` | 상위 메시지와 첫 CTA |
| `problems` | 사용자가 겪는 문제 제시 |
| `products` | Chatdox·Claudox 비교와 진입 |
| `proof` | 실제 콘텐츠 근거 제시 |
| `guide` | 목표에 따른 상품 선택 안내 |
| `about` | LEEDOX가 기록하는 이유 |
| `faq` | 공통 질문과 답변 |
| `cta` | 상품 비교 영역으로 재진입 |

partial의 기준은 화면을 무조건 잘게 자르는 것이 아니라 한 부분이 하나의 설명 책임을 갖도록 하는 것입니다.

## 5. 반응형 UI와 한국어 줄바꿈

```erb
<h1 class="mt-7 break-keep text-4xl font-black sm:text-6xl">
  AI와 함께 일하는 방법을,<br class="hidden sm:block">
  <span>실제 결과물로</span> 보여드립니다.
</h1>
<div class="mt-9 flex flex-col gap-3 sm:flex-row">
  <!-- CTA -->
</div>
```

- 모바일 `text-4xl`에서 `sm:text-6xl`로 확대
- `flex-col`에서 `sm:flex-row`로 전환
- 상품 카드는 한 열에서 `lg:grid-cols-2`로 전환
- 데스크톱 nav는 `hidden ... md:flex`, 모바일 메뉴는 `md:hidden`

모바일 검토에서 제목이 `방법/을`, `구축하/기`처럼 갈라졌습니다. 제목 중심으로 `break-keep`을 적용했습니다.

```css
.break-keep { word-break: keep-all; }
```

긴 공백 없는 문자열은 여전히 넘칠 수 있으므로 수평 overflow도 확인합니다.

```javascript
document.documentElement.scrollWidth <= window.innerWidth
```

## 6. 검증을 두 층으로 나누기

### Rails 통합 테스트

`test/integration/leedox_home_test.rb`는 다음을 확인합니다.

1. 통합 홈이 LEEDOX와 두 상품을 보여주되 미확정 가격을 노출하지 않는다.
2. 비로그인 Header가 데스크톱·모바일 인증 진입점을 유지한다.
3. 로그인 Header가 계정 정보와 로그아웃 동작을 유지한다.
4. `/chatdox`가 기존 랜딩 섹션을 보존한다.
5. `/claudox`와 기존 핵심 진입점이 계속 접근 가능하다.

```text
bin/rails test
5 runs, 49 assertions, 0 failures, 0 errors, 0 skips
```

### 실제 브라우저 검증

통합 테스트만으로 CSS 배치, focus 이동, Console을 확인할 수는 없습니다. Headless Chrome의 375px, 768px, 1440px에서 확인했고 최종 R2에서는 375px과 1440px를 재검증했습니다.

- 수평 overflow가 없는가
- Tab으로 주요 링크와 메뉴에 접근할 수 있는가
- Enter/Space로 `<details>`를 열고 닫을 수 있는가
- Console error와 unhandled rejection이 없는가

브라우저 검증기는 일회성이며 지속 실행 테스트가 아닙니다. 실제 기기, Safari, Firefox, touch interaction까지 검증한 것으로 확대 해석하면 안 됩니다.

## 7. Learn — 구현 후 남은 원칙

1. 브랜드 홈과 상품 홈의 목적을 먼저 구분합니다.
2. 기존 유효 경로를 새 화면으로 성급하게 덮어쓰지 않습니다.
3. View 조합과 partial의 책임을 명확히 나눕니다.
4. 인증·권한 분기는 데스크톱과 모바일에서 함께 검증합니다.
5. 테스트 통과와 실제 화면 검증을 서로 다른 증거로 관리합니다.
6. 첫 결과를 독립적으로 검토하고 발견된 문제를 R2로 닫습니다.

## 현재 구현의 한계

- `/claudox`는 별도 마케팅 상세 페이지가 아니라 기존 문서 뷰어입니다.
- `/chatdox`의 기존 가격·무료 체험 문구는 통합 상품 정책의 확정을 뜻하지 않습니다.
- 관리자 Header의 긴 이메일과 중간 데스크톱 폭 혼잡은 별도 검증되지 않았습니다.
- `proof`의 Claudox 목차는 정적 배열입니다.
- `mobile_navigation_items` helper는 현재 Header에서 사용되지 않습니다.
- 저장소에 지속 실행되는 브라우저 회귀 테스트는 없습니다.

교육 문서에서는 구현된 사실, 검증 범위, 아직 결정되지 않은 사업 정책을 구분해야 합니다.

## 완료 체크리스트

- [ ] `/`, `/chatdox`, `/claudox`의 역할을 설명할 수 있다.
- [ ] 기존 partial을 복사하지 않고 재사용할 수 있다.
- [ ] 인증 상태별 Header를 데스크톱과 모바일에서 확인한다.
- [ ] 375px 화면에서 한국어 제목과 수평 overflow를 확인한다.
- [ ] 통합 테스트와 브라우저 검증의 차이를 설명할 수 있다.
- [ ] 구현의 한계와 미확정 정책을 결과 보고에 남긴다.

## 관련 문서

- [4. 랜딩페이지 구축](04_landing_page.md)
- [7. 사용자 인증](07_authentication.md)
- [8. 권한 관리](08_authorization.md)
