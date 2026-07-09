---
title: "Subtree 협업 규칙 & Docs-Curriculum 읽기 전용 정책"
date: "2026-07-09"
category: "Git"
difficulty: "중급"
related: ["TIPS/02_git_subtree.md", "SETUP/02_rails_platform_setup.md", "QA/01_github_strategy.md"]
---

# Subtree 협업 규칙 & Docs-Curriculum 읽기 전용 정책

`chatdox-curriculum`을 `chatdox-platform`에 Subtree로 포함할 때 지켜야 할 협업 규칙을 정의합니다.

---

## 🎯 이 팁을 읽어야 하는 경우

- Platform 개발자인데, docs/curriculum 파일을 수정해야 할 때
- Curriculum 변경사항이 필요한데 어떻게 요청할지 모를 때
- 타이포나 오류를 발견했을 때
- Subtree 사용 시 협업 규칙이 궁금할 때

---

## 📋 핵심: Subtree의 "계약(Contract)"

Subtree는 **단방향 관계**입니다:

```
chatdox-curriculum (출처 저장소)
    ↓ Add (처음 1회)
    ↓ Pull (필요할 때, 읽기 전용)
    ↓
chatdox-platform/docs/curriculum/
    ↑ Push는 금지 ❌
```

---

## ✅ 규칙: docs/curriculum/은 읽기 전용

### 규칙 1️⃣ Platform 개발자는 수정 금지

```bash
❌ 금지
cd chatdox-platform
vim docs/curriculum/TIPS/02_git_subtree.md  # 수정
git add docs/curriculum/
git commit -m "fix: typo in TIPS/02"

✅ 대신 이렇게 하세요
# (아래 "변경 요청하기" 섹션 참고)
```

### 규칙 2️⃣ 읽기는 자유

```bash
✅ 가능
cd chatdox-platform
cat docs/curriculum/docs/04_landing_page.md  # 읽기
grep -r "Devise" docs/curriculum/             # 검색
# Platform 개발에 참고하세요!
```

### 규칙 3️⃣ Curriculum 변경은 curriculum 세션에서만

```bash
✅ curriculum 세션에서
cd chatdox-curriculum
vim TIPS/02_git_subtree.md  # 수정
git add .
git commit -m "docs(TIPS/02): fix merge editor FAQ"
git push origin main

그 다음 Platform 세션에서:
cd chatdox-platform
git subtree pull --prefix docs/curriculum \
  https://github.com/[USERNAME]/chatdox-curriculum.git main --squash
```

---

## 🔄 변경 요청하기 (3가지 방법)

### 방법 1️⃣ GitHub Issue (추천)

Platform 세션에서:

```bash
# chatdox-curriculum 저장소의 Issues 탭 열기
# https://github.com/[USERNAME]/chatdox-curriculum/issues/new

# 제목: "[docs/04] Hero 섹션 이미지 경로 수정 필요"
# 내용:
# docs/04_landing_page.md 의 Hero 섹션에서
# *img1.jpg* 경로가 실제 이미지 파일 위치와 맞지 않습니다.
# 
# 현재: *img1.jpg*
# 제안: *public/images/hero.jpg*
```

**장점:**
- 기록이 남음
- 누가 요청했는지 추적 가능
- 나중에 같은 이슈 찾기 쉬움

### 방법 2️⃣ Curriculum 세션으로 전환

Platform 세션에서 작업 중:

```
"타이포 발견: docs/04_landing_page.md 에서 
'서비스'가 '써비스'로 잘못 됨.

→ Curriculum 세션으로 전환해서 수정하자!"

(세션 전환)

✅ Curriculum 세션에서 수정 & 커밋 & 푸시
✅ Platform 세션으로 돌아옴
✅ git subtree pull로 최신 내용 동기화
```

**장점:**
- 빠름
- 즉시 반영 가능

### 방법 3️⃣ Todo 리스트에 기록

Platform 세션 내에서:

```bash
# .cursorrules 또는 프로젝트 노트에 기록
# Platform 작업 중 발견한 curriculum 개선사항:
# - [ ] TIPS/02: Merge editor FAQ 추가 (타이포 설명 추가)
# - [ ] docs/04: Hero 이미지 경로 확인
# - [ ] prompts/01: Tailwind 클래스 예시 추가

# (작업 완료 후) 정리하면서 한번에 처리
```

**장점:**
- 배치 처리 가능 (여러 변경사항 한번에)
- 우선순위 정리 가능

---

## 📊 정책 비교

| 정책 | 특징 | 효과 |
|------|------|------|
| **읽기 전용** ✅ | Platform에서 수정 금지, 요청으로 관리 | Git 히스토리 명확, 충돌 없음, 역할 분리 |
| **선택적 수정** | 긴급/타이포만 허용 | 유연하지만 이력 추적 복잡 |
| **자유 수정** | Platform에서도 수정 | 빠르지만 Subtree Push 필요, 히스토리 복잡 |

---

## 💡 핵심 이유

### 1️⃣ Git 히스토리 명확화

```
curriculum 저장소 (Single Source of Truth)
├─ Commit 1: "docs: Add TIPS/02"        ← Curriculum 팀
├─ Commit 2: "docs: fix typo in FAQ"    ← Curriculum 팀
└─ Commit 3: "TIPS/02: merge editor"    ← Curriculum 팀

platform 저장소 (Consumer)
├─ Commit 10: "feat: landing page"     ← Platform 팀
├─ Commit 11: "Merge subtree curriculum" ← git subtree pull
└─ Commit 12: "feat: auth pages"       ← Platform 팀
```

**읽기 전용이면:**
- Platform 커밋과 Curriculum 커밋이 섞이지 않음
- 누가 뭘 수정했는지 추적 쉬움

### 2️⃣ 충돌 관리 단순화

```
❌ Platform에서도 수정하면:
curriculum 저장소에서: "docs: add FAQ"
platform 저장소에서: "docs: fix typo"
        ↓
git subtree pull 시 충돌 발생!
"어느 것이 맞는 버전?"

✅ 읽기 전용이면:
curriculum 저장소에서: "docs: add FAQ" + "fix: typo"
platform 저장소에서: 변경 없음
        ↓
git subtree pull 시 자동 merge
충돌 없음!
```

### 3️⃣ 역할 분리 명확화

```
Curriculum 팀 (콘텐츠 전문)
├─ 20개 챕터 작성
├─ 코드 예시 업데이트
├─ 오타/버그 수정
└─ 최신 기술 정보 반영

Platform 팀 (구현 전문)
├─ Rails 기능 개발
├─ UI/UX 구현
├─ 사용자 기능 개발
└─ docs/curriculum 참고만 함 (읽기 전용)
```

---

## 🔍 예시 시나리오

### 시나리오 1️⃣: Platform 개발 중 타이포 발견

```
상황:
Platform 개발자가 "docs/curriculum/docs/04_landing_page.md" 읽다가
"써비스"라는 타이포 발견

✅ 올바른 방법:

1단계: Curriculum 세션으로 전환
  $ cd ../curriculum-session
  $ vim docs/04_landing_page.md
  $ sed -i 's/써비스/서비스/g' docs/04_landing_page.md

2단계: Commit & Push
  $ git add docs/04_landing_page.md
  $ git commit -m "docs(04): fix typo - 써비스 → 서비스"
  $ git push origin main

3단계: Platform 세션에서 동기화
  $ cd ../platform
  $ git subtree pull --prefix docs/curriculum \
      https://github.com/[USERNAME]/chatdox-curriculum.git main --squash
  $ git add .
  $ git commit -m "chore: sync curriculum (typo fix)"
```

### 시나리오 2️⃣: 새로운 챕터 필요

```
상황:
Platform 개발자가 "챕터 05: 프로젝트 구조 설계" 필요함

✅ 올바른 방법:

1단계: GitHub Issue 생성
  Title: "[docs] Chapter 05 필요: 프로젝트 구조 설계"
  Body: 
    Platform의 랜딩페이지 다음 단계로 
    프로젝트 구조를 설명하는 챕터가 필요합니다.
    대략적 목차:
    - Rails 폴더 구조
    - Model/View/Controller 조직화
    - 설정 파일 이해

2단계: Curriculum 팀이 응답
  "05_project_structure.md 작성 예정입니다.
   2026-07-10까지 완성하겠습니다."

3단계: 완성 후 Platform에서 pull
  $ git subtree pull --prefix docs/curriculum \
      https://github.com/[USERNAME]/chatdox-curriculum.git main --squash
```

### 시나리오 3️⃣: 긴급 수정 필요 (예외 상황)

```
상황:
Platform 배포 전에 docs/curriculum에 보안 관련 오류 발견
즉시 수정 필요!

✅ 긴급 예외 처리:

1단계: Platform에서 직접 수정 (임시)
  $ vim docs/curriculum/docs/18_security.md  # 수정
  $ git add docs/curriculum/
  $ git commit -m "hotfix(curriculum): security issue
  
  [CURRICULUM-SYNC] This is a temporary platform-side fix.
  Please review and merge into chatdox-curriculum ASAP."

2단계: 나중에 curriculum 세션에서 검토
  - GitHub Issue 확인
  - 수정 내용 검토
  - curriculum 저장소에 반영
  - Platform에서 pull

⚠️  주의: [CURRICULUM-SYNC] 태그를 붙여서 
    나중에 쉽게 찾을 수 있도록 함
```

---

## 📝 체크리스트

### Platform 개발자용

- [ ] docs/curriculum/ 폴더는 **읽기만** 한다
- [ ] 수정이 필요하면 **GitHub Issue** 또는 **Curriculum 세션**으로 요청한다
- [ ] 정기적으로 **git subtree pull**로 최신 curriculum을 동기화한다
- [ ] Pull 후 자동 merge commit이 생성되는 것을 이해한다

### Curriculum 개발자용

- [ ] Platform에서 온 변경 요청을 정기적으로 확인한다
- [ ] 변경사항을 curriculum 저장소에 커밋한다
- [ ] Platform 팀에 "완료" 알림을 준다

### Team Lead용

- [ ] 정기적으로 (주 1회) docs/curriculum 동기화 스케줄 확인
- [ ] Platform ↔ Curriculum 간 요청사항 추적
- [ ] 충돌이 발생했을 때 해결 프로세스 준비

---

## 🛠️ Git 명령어 정리

### Platform에서 curriculum 동기화

```bash
# 최신 버전 가져오기
git subtree pull --prefix docs/curriculum \
  https://github.com/[USERNAME]/chatdox-curriculum.git main --squash

# 히스토리 압축 확인
git log --oneline | head -5

# 변경사항 확인
git diff HEAD~1..HEAD -- docs/curriculum/
```

### Curriculum 수정 후 Platform에 알림

```bash
# curriculum 저장소에서
git push origin main

# Platform 팀에게 알림
# GitHub Issue 또는 메시지:
# "Curriculum 업데이트 완료: TIPS/02, TIPS/03 추가"
```

---

## 💬 자주 묻는 질문

**Q: Platform에서 빨리 수정해야 하는데 계속 요청해야 하나?**  
A: 대부분의 경우 요청하세요. 긴급 상황([CURRICULUM-SYNC] 태그)이면 임시 수정 후 나중에 정리합니다.

**Q: 내가 직접 git subtree push로 Platform 변경사항을 curriculum에 반영할 수 있나?**  
A: 기술적으로는 가능하지만, 역할 혼동을 피하기 위해 하지 않기를 권장합니다. Curriculum 팀을 통해 요청하세요.

**Q: docs/curriculum을 수정해야만 하는 상황이 있나?**  
A: 드문 경우들:
  - 보안 이슈 긴급 수정
  - 배포 직전 심각한 오류
  - 이런 경우 Platform에서 수정 후, 나중에 curriculum 팀이 검토/승인

**Q: `git subtree pull` 실행 시 "fatal: working tree has modifications. Cannot add." 에러가 나요.**  
A: Platform에 커밋되지 않은 변경사항이 있다는 뜻입니다. Git merge 작업이 필요한데 working tree가 깨끗해야 합니다.

해결:
```bash
# 방법 1: 커밋하고 pull (권장)
git add .
git commit -m "feat: update landing page"
git subtree pull --prefix docs/curriculum https://... main --squash

# 방법 2: Stash & pull
git stash
git subtree pull --prefix docs/curriculum https://... main --squash
git stash pop
```

**Q: Subtree Pull 중 충돌이 나면?**  
A: 
  1) Platform에서 docs/curriculum 파일을 수정한 경우
  2) `git checkout -- docs/curriculum/` 로 변경사항 버리기
  3) 다시 `git subtree pull` 실행
  4) 필요한 수정은 curriculum 팀 요청

**Q: 얼마나 자주 pull해야 하나?**  
A: 권장:
  - 일일 (자동화 가능)
  - 주 3회 (수동)
  - 특정 작업 전 (예: landing page 구현 전)

---

## 📚 관련 문서

- [TIPS/02_git_subtree.md](02_git_subtree.md) — Git Subtree 개념 및 원리
- [SETUP/02_rails_platform_setup.md](../SETUP/02_rails_platform_setup.md) — Subtree Add 방법
- [QA/01_github_strategy.md](../QA/01_github_strategy.md) — 2-repo 전략 배경

---

## 🎯 핵심 정리

```
Platform 개발자의 습관:

1. docs/curriculum 읽기 ✅
2. 변경 필요 → 요청 ✅
3. Curriculum 팀이 수정 → 커밋 & 푸시 ✅
4. Platform에서 Pull → 동기화 완료 ✅

이 순환이 깔끔한 협업을 만듭니다!

"읽기 전용 = 신뢰와 명확함"
```

---

**마지막 업데이트:** 2026-07-09
