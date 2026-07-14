# 심화 사례: 상품 페이지와 문서 뷰어를 안전하게 분리하기

> LEEDOX 통합 홈 다음 단계에서 Chatdox 가격 정책을 바꾸고 Claudox 상품 페이지를 추가한 실제 사례입니다. 최종 코드, 테스트와 R1→R2 결과 보고를 근거로 작성했습니다.

## 이 사례에서 배우는 것

- 상품 상세페이지와 구매 후 콘텐츠 뷰어의 URL 책임 분리
- 권한 로직을 유지하면서 route만 이동하는 방법
- 파일 존재와 콘텐츠 완성도를 다른 상태로 모델링하는 이유
- 미확정 정책이 UI 약속으로 번지는 것을 막는 방법
- 자동 테스트, 정적 확인과 브라우저 확인의 증거 수준 구분

## 1. Why — 상품 정의가 바뀌었다

기존 `/chatdox`에는 월 구독, 무료 체험과 프리미엄 대기 UI가 있었습니다. 새 방향은 단품 9,900원, 평생 접근, 구매 후 1년 무료 업데이트, 개인 라이선스와 7일 환불이었습니다. 단, 가격 자체와 단품 결제 흐름은 여전히 검증 중이었습니다.

Claudox에는 또 다른 문제가 있었습니다. `/claudox`가 곧바로 문서 뷰어를 열어 상품을 이해하고 구매를 판단할 상세페이지가 없었습니다.

- Chatdox: 오래된 구독 표현을 새 단품 정책으로 교체
- Claudox: 상품 소개와 실제 읽기 화면을 분리
- 공통: 기존 결제 데이터와 문서 접근 권한은 변경하지 않음

## 2. How — URL을 역할에 맞게 다시 설계하기

```ruby
get "/chatdox", to: "pages#chatdox", as: :chatdox
get "/claudox", to: "claudox_products#show", as: :claudox
get "/claudox/read", to: "claudox#index", as: :claudox_read
get "/claudox/read/:id", to: "claudox#show", as: :claudox_chapter
```

| 경로 | 책임 |
|---|---|
| `/chatdox` | Chatdox 상품 상세와 단품 조건 |
| `/claudox` | Claudox 상품 상세 |
| `/claudox/read` | 기존 Claudox 문서 목록 |
| `/claudox/read/:id` | 권한 확인을 거치는 개별 챕터 |

R1에서는 기존 뷰어를 건드리지 않으려고 상세페이지를 `/claudox/intro`에 만들었습니다. 화면 검토 결과 `/chatdox`와 정보 구조가 비대칭이라는 문제가 드러났습니다. R2에서는 `/claudox`를 대표 경로로 승격하고 읽기 동작을 `/claudox/read` 아래로 옮겼습니다.

`ClaudoxController`와 `DocPolicy`는 수정하지 않았습니다. `claudox_chapter_path` helper 이름도 유지하고 URL만 재계산되게 했습니다.

> 코드가 변경되지 않았다는 것은 좋은 정적 근거지만, 게스트·트라이얼·구독·관리자 네 역할을 새 URL에서 모두 실행 검증했다는 뜻은 아닙니다. 현재 자동 테스트는 게스트가 읽을 수 있는 01번 챕터만 확인합니다.

## 3. 정책은 표시하되 확정 범위를 넘지 않기

```erb
<% checkout_or_login_path = user_signed_in? ? billing_checkout_path : new_user_session_path %>
```

화면에는 단품 조건과 함께 “검증 중인 가설 가격”, “실제 단품 결제 흐름은 검증 중이며 현재는 기존 결제 경로로 연결”된다는 한계를 표시했습니다. 기존 결제 Controller, Subscription과 PaymentTransaction 모델, schema와 migration은 변경하지 않았습니다.

- 표시하기로 결정한 조건: 9,900원, 평생 접근, 1년 업데이트, 개인 라이선스, 7일 환불
- 아직 확정하지 않은 실행: 최종 가격과 단품 전용 결제 UX

## 4. 파일 존재와 콘텐츠 완성도는 다르다

20개 챕터 파일은 모두 존재하지만 일부는 제목과 미작성 표시만 있습니다. R1은 파일 존재 여부를 완성 여부처럼 사용해 `완성 20 / 20`으로 표시했습니다. R2는 `available`과 `complete`를 분리했습니다.

```ruby
chapter_file = chapter_files.find { |filename| filename.match?(/\A#{number}_/) }
available = chapter_file.present?

{
  number: number,
  title: title,
  available: available,
  complete: available && chapter_written?(chapter_file),
  id: chapter_file&.delete_suffix(".md")
}
```

```ruby
UNWRITTEN_PLACEHOLDER = "*(아직 작성되지 않음)*"

def chapter_written?(filename)
  !File.read(@claudox_dir.join(filename)).include?(UNWRITTEN_PLACEHOLDER)
end
```

현재 `완성 11 / 20`과 각 카드의 `완성`·`준비 중` 상태가 구분됩니다. 그러나 플레이스홀더만 지우면 덜 작성된 글도 완료가 됩니다. `88_progress.md`의 정성적 80% 기준과 코드로 연결된 단일 source of truth는 아닙니다.

## 5. R1 검토가 R2를 만들었다

R1은 테스트를 통과했지만 화면 검토에서 세 문제가 발견됐습니다.

1. 모든 챕터가 `완성`으로 잘못 표시됨
2. `/claudox`와 `/claudox/intro`가 상품 구조를 비대칭으로 만듦
3. 요청하지 않은 커뮤니티·오피스아워·코드리뷰 크레딧 등이 “선택형 운영 지원”으로 노출됨

세 번째 문제는 특히 중요합니다. 구현 결과는 해당 기능을 미결정 사항이라고 보고했지만 화면은 이미 제공 예정 기능처럼 약속했습니다. 확정되지 않은 기능은 문구를 약하게 만드는 대신 화면에서 제거했습니다.

R2는 R1 전체를 다시 만들지 않고 이 세 항목만 델타 요청으로 수정했습니다.

> R1 버그 코드는 하나의 스쿼시 커밋 때문에 Git 이력에 남아 있지 않습니다. R1 설명은 결과 보고의 조사 기록을 바탕으로 재구성했으며 실제 R1 diff에서 발췌한 코드가 아닙니다. 최종 R2 코드는 저장소에서 직접 확인했습니다.

## 6. 테스트가 증명한 것과 증명하지 않은 것

```text
bin/rails test test/integration/leedox_home_test.rb
7 runs, 83 assertions, 0 failures, 0 errors, 0 skips
```

테스트는 `/chatdox`의 단품 조건과 미확정 기능 비노출, `/claudox`의 `완성 11 / 20`, CH01 완성·CH06 준비 중, 새 읽기 경로와 메인 홈 가격 비노출을 확인했습니다.

반면 다음은 충분히 증명하지 않습니다.

- 트라이얼·구독·관리자별 전체 `DocPolicy` 접근 수준
- 실제 Tab 순서와 키보드 조작
- Safari, Firefox와 실제 모바일 기기
- 지속적인 브라우저 회귀

최종 PNG는 1440px 데스크톱과 390px 모바일에서 생성됐습니다. Headless Chrome 캡처와 서버 로그 확인 기록은 있지만 키보드 실사용 검증 기록은 없습니다. `focus-visible` 클래스와 실제 키보드 검증은 서로 다른 증거입니다.

## 7. Learn — 재사용할 원칙

1. URL은 구현 편의보다 사용자가 기대하는 자원 역할을 반영합니다.
2. route를 옮길 때 Controller·Policy·helper를 각각 추적합니다.
3. “존재함”과 “완료됨”을 같은 boolean으로 표현하지 않습니다.
4. 미확정 기능은 현재의 과도한 약속이 될 수 있습니다.
5. 테스트 통과 뒤에도 Product Owner의 화면 검토가 필요합니다.
6. R2는 전체 재작업보다 검증된 델타에 집중합니다.
7. 코드, 결과 보고와 재구성한 설명의 증거 수준을 구분합니다.

## 현재 한계

- 9,900원은 최종 확정 가격이 아닙니다.
- 단품 전용 결제 플로우가 없고 기존 checkout을 재사용합니다.
- 완성도 판정이 특정 플레이스홀더 문자열에 결합되어 있습니다.
- 옛 `/claudox/intro`와 `/claudox/:id`는 redirect 없이 404가 됩니다.
- 네 사용자 역할별 문서 권한 회귀 테스트가 없습니다.
- 지속 실행되는 browser/system test가 없습니다.

## 관련 문서

- [심화 사례: 단일 상품 홈을 LEEDOX 통합 홈으로 확장하기](case_leedox_integrated_home.md)
- [8. 권한 관리](08_authorization.md)
- [9. 결제 시스템](09_payment.md)
