# CLAUDE.md

이 파일은 이 프로젝트에서 반복적으로 필요한 맥락(환경 특이사항, 작업 규칙, 아키텍처 결정, 겪은 실수와 교훈)을 담는다. 세션이 새로 열릴 때마다 가장 먼저 읽을 것.

**이 문서의 규칙이 실제로 적용되는 순간(예: request.md를 곧이곧대로 믿지 않고 추가로 grep한다, 마이그레이션 후 Railway 실행을 상기시킨다 등)에는 조용히 그냥 하지 말고, 대화에서 "CLAUDE.md 규칙에 따라 ~" 식으로 명시적으로 언급할 것.**

## 프로젝트 구조: DEV / HQ

- 이 저장소(`chatdox-platform`)는 **DEV** — 실제 코드가 사는 곳.
- 커리큘럼/handoff 저장소는 **HQ** (`chatdox-curriculum`). 이 WSL 환경에서는 `/mnt/d/RubyOnRails/chatdox-curriculum`에 마운트되어 있다.
- Handoff 작업 흐름:
  1. HQ가 `.local/handoff/inbox/<package>/request.md`를 만든다.
  2. DEV는 `script/sync_handoff.sh`(`--dry-run`으로 먼저 확인 후 `--mirror`)로 HQ의 `.local/handoff/`를 이 저장소의 `.local/handoff/`로 끌어온다. `--mirror`는 HQ에 없는 로컬 전용 파일/폴더(예: `outbox/`)까지 지우는 진짜 미러링이므로 실행 전 `--dry-run` 결과를 반드시 확인한다.
  3. 구현 후 `.local/handoff/inbox/<package>/result.md`를 작성하고, HQ 쪽 대응 경로(`/mnt/d/RubyOnRails/chatdox-curriculum/.local/handoff/inbox/<package>/`)에 `cp`로 직접 복사해 전달한다 — 반대 방향(DEV→HQ) 자동 스크립트는 아직 없다.
- **"완료(completed)" 판정과 STATUS.md는 HQ의 권한이다.** DEV가 임의로 STATUS.md를 지어내지 말 것. "HQ에서 completed 처리했다"는 말을 들으면 직접 작성하지 말고 `script/sync_handoff.sh --mirror`로 HQ의 실제 사본을 가져올 것.
- `.local/`은 `.gitignore`에 포함되어 커밋되지 않는다 — handoff 패키지, STATUS.md, 참고 정책 문서 등은 전부 로컬 전용이고, git 이력에는 실제 코드/테스트/마이그레이션만 남는다.

## 환경 특이사항

- 이 WSL 네이티브 클론에는 headless 브라우저/스크린샷 도구와 sudo가 없다. 스크린샷이 필요한 검증 요청이 오면 먼저 사용자에게 처리 방법을 물어볼 것 — 많은 경우 curl 기반 HTML/텍스트 검증으로 대체 가능하다.
- DB는 SQLite. `bin/rails db:migrate`는 development 환경에만 적용된다 — 테스트가 새 스키마를 보게 하려면 `RAILS_ENV=test bin/rails db:schema:load`를 별도로 실행해야 한다.
- **`git push`로는 코드만 Railway에 자동 배포되고, 마이그레이션은 자동 실행되지 않는다.** 스키마 변경이 있는 작업 뒤에는 배포 후 `railway run bin/rails db:migrate`가 별도로 필요하다는 것을 항상 상기시킬 것(2026-07-16 하루에만 User#name 필드, Subscription 테이블 drop, GitHub access 테이블 drop 세 건 모두 이 문제가 있었다).

## 작업 규칙 (Tommy와의 협업 패턴)

- 작업 요청은 `.local/handoff/inbox/<package>/request.md`로 온다. 문서 맨 끝 "Platform 실행 문구" 섹션이 실제 지시사항.
- 구현 후에는 거의 항상 커밋 + push, 그리고 `result.md`로 (조사 결과 / 실제 채택한 설계와 제안 대비 달라진 점 + 이유 / 변경·삭제 파일 / 테스트 결과 / 미결정 사항) 보고하는 게 표준 패턴이다.
- **request.md의 "현재 코드 확인 완료, 재조사 불필요"를 그대로 믿지 말 것.** 실제로 매 작업마다 request.md가 나열하지 않은 관련 참조가 더 있었다(예: Toss/Subscription 제거 때 admin 컨트롤러 4곳 + `Commerce::Reconciliation`/`EventLogger`, GitHub access 단순화 때 `event_recorder.rb`/`task_factory.rb` + `Commerce::Reconciliation`). 삭제·리팩터링 대상 클래스/모델명으로 항상 sitewide grep을 먼저 돌려 숨은 참조를 확인한다.
- "코드량을 최대한 줄이는 것"처럼 명시적 단순화 목표가 있는 작업에서는, 요청서의 제안 설계보다 더 간단한 방법이 보이면 조정해도 되는 재량이 주어진다 — 다만 `result.md`에 무엇을 왜 다르게 했는지 반드시 남긴다.
- 커밋 메시지는 `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`로 끝맺는 관례를 따른다.

## 알게 된 실수와 교훈

- **`has_one` 연관 + `dependent: :restrict_with_error` 상태에서 `owner.build_association(...)`을 이미 연관이 존재하는데 다시 호출하면 `ActiveRecord::RecordNotSaved`가 발생한다** (Rails가 기존 레코드를 "교체"하려다 restrict에 막힘). 존재 여부를 먼저 확인하고, 필요하면 `Model.new(user: owner, ...)`으로 직접 생성해 이 replace 시맨틱 자체를 피할 것. (2026-07-16, GitHub access 단순화 작업 중 수동 curl 검증으로 발견. 흥미롭게도 동일 시나리오의 자동 통합 테스트(`assert_no_difference`)는 이 예외를 잡아내지 못했고 원인은 못 밝혔다 — `bin/rails test` 통과만으로 안심하지 말고 실제 화면 조작을 흉내 낸 수동 검증을 병행할 것.)
- 라우트 헬퍼 이름은 `namespace :admin { namespace :commerce { ... as: :foo } }`이면 `admin_commerce_foo_path`가 된다(네임스페이스 접두사가 지정한 이름 앞에 붙는다) — `foo_admin_commerce_path`처럼 순서를 반대로 짐작해서 쓰면 뷰 렌더링 시점에야 `NoMethodError`로 드러난다. `bin/rails routes`로 실제 이름을 확인하고 쓸 것.
- 마이그레이션에서 테이블을 drop할 때는 그 테이블을 참조하는 FK부터 `remove_foreign_key`로 먼저 제거하고, 여러 테이블이 서로 참조하면 참조받는 쪽이 없어지기 전에 참조하는 쪽부터 순서대로 drop한다(예: `events → tasks → grants`). `drop_table`에 컬럼 정의 블록을 넣어두면 롤백 시 원래 스키마로 복원되는 reversible 마이그레이션이 된다.

## 참고 문서

- `.local/claudox/chatdox_golive_simplification_2026-07-16.md` — Chatdox GoLive 단순화 작업 전체의 배경과 의사결정 근거. Toss/Subscription 제거, GitHub access MVP 단순화, 법무 문서 정합화 같은 관련 작업들이 이 문서를 공통 참조로 삼는다.
