---
title: "Git Subtree 개념과 실무 활용"
date: "2026-07-09"
category: "Git"
difficulty: "중급"
related: ["SETUP/02_rails_platform_setup.md", "QA/01_github_strategy.md"]
---

# Git Subtree 개념과 실무 활용

`chatdox-curriculum`을 `chatdox-platform`에 포함할 때 사용한 **Git Subtree** 방식을 깊이 있게 이해합니다.

---

## 🎯 이 팁을 읽어야 하는 경우

- Subtree가 뭔지 정확히 알고 싶다
- "Pull만 하면 되는 거 아닌가?" 하는 의문이 있다
- Subtree vs Submodule vs 직접 복사의 차이가 궁금하다
- Subtree 업데이트 방법을 알고 싶다
- Subtree로 인한 Git 히스토리가 복잡해질까봐 걱정된다

---

## 📋 배경: 왜 Subtree가 필요한가?

### 상황
```
chatdox-curriculum (상품: 교과서)
    ├─ docs/ (20개 챕터)
    ├─ prompts/ (UI/UX 설계)
    ├─ QA/ (의사결정 기록)
    └─ GitHub (Private)

chatdox-platform (실제 구현: Rails 앱)
    ├─ app/
    ├─ config/
    └─ GitHub (Public)

🤔 문제: Platform 개발자가 curriculum 문서에 접근하려면?
```

### 해결책 3가지

| 방식 | 파일 위치 | 첫 설정 | 업데이트 | 히스토리 | 추천 상황 |
|------|---------|--------|---------|---------|----------|
| **Subtree** | Platform에 포함 | git subtree add | git subtree pull | 병합됨 | ✅ 우리 선택 |
| **Submodule** | 별도 참조 | git submodule add | git submodule update | 분리됨 | 완벽한 독립성 필요 |
| **직접 복사** | 수동 복사 | 수동 | 수동 | 없음 | 복잡도 최소 |

---

## ✅ Git Subtree의 원리

### 1️⃣ **Subtree Add** (처음, 1회만)

```bash
git subtree add --prefix docs/curriculum \
  https://github.com/[USERNAME]/chatdox-curriculum.git main
```

**이 명령어가 하는 일:**

```
Step A: Curriculum 리포 복제
  curriculum/.git/
  ├─ 01_overview.md (commit: aaa111)
  ├─ 02_rails_basics.md (commit: aaa222)
  └─ (모든 히스토리)

Step B: Platform의 docs/curriculum/ 폴더로 복사
  platform/docs/curriculum/
  ├─ 01_overview.md ← 복사됨
  ├─ 02_rails_basics.md ← 복사됨
  └─ (전체 히스토리도 포함)

Step C: Platform의 .git에 메타데이터 저장
  platform/.git/
  ├─ objects/ (curriculum의 모든 커밋 포함)
  ├─ refs/
  └─ subtree-splits/ ← Subtree 추적 정보
  
Step D: Platform에 새 커밋 생성
  commit abc123: Add curriculum subtree
```

**결과:**
```
Platform 개발자가 클론하면:
$ git clone https://github.com/[USERNAME]/chatdox-platform.git
$ cd chatdox-platform
$ ls docs/curriculum/
# → docs/, prompts/, QA/ 모두 보임! ✅
# → Pull 불필요! Curriculum이 이미 포함됨
```

---

### 2️⃣ **평소 작업** (대부분의 시간)

```bash
# Platform 개발자는 일반 파일처럼 사용
$ cat docs/curriculum/docs/04_landing_page.md
$ vim docs/curriculum/SETUP/02_rails_platform_setup.md
# (읽기 전용, 수정하지 않기)
```

**중요:** Subtree 폴더는 **Platform에서 수정하면 안 됩니다!**
- ❌ `docs/curriculum/` 아래 파일을 Platform에서 수정
- ✅ 수정이 필요하면 `chatdox-curriculum` 리포에서 수정

---

### 3️⃣ **Subtree Pull** (필요할 때)

Curriculum이 업데이트되면:

```bash
# Curriculum 리포 (다른 개발자가)
$ cd d:\dev\chatdox-curriculum
$ git add .
$ git commit -m "Add chapter 5"
$ git push origin main

# Platform 리포 (동기화)
$ cd d:\dev\chatdox-platform
$ git subtree pull --prefix docs/curriculum \
    https://github.com/[USERNAME]/chatdox-curriculum.git main --squash

# Platform에 새 커밋 생성
$ git log --oneline
# abc124 Merge curriculum updates (← 새로운 커밋)
# abc123 Add curriculum subtree

# Push
$ git push origin main
```

**Pull이 하는 일:**
- ✅ Curriculum 리포의 **최신 변경**만 가져옴
- ✅ Platform의 `docs/curriculum/` 병합
- ✅ Platform에 새로운 커밋 생성
- ✅ Git 히스토리는 깔끔함 (--squash 옵션)

---

## 🎯 "Pull만 하면 되나?" 질문에 대한 답

### ❌ 잘못된 이해

```
"Subtree 폴더가 있으니 Pull만 하면 되겠지?"
→ 아닙니다!
```

### ✅ 정확한 이해

```
Timeline:

[Day 1]
- Platform 리포에서 "git subtree add" 실행
- Curriculum의 모든 파일이 Platform의 docs/curriculum/에 복사
- Platform 개발자들이 클론하면 curriculum이 이미 있음
- 👉 Pull 필요 없음!

[Day 5]
- Curriculum 리포에 새로운 chapte 5 추가
- Platform에서 이를 가져오려면?
- 👉 "git subtree pull" 실행해야 함!

[Day 10]
- 또 다른 업데이트 발생
- 👉 다시 "git subtree pull"
```

### 핵심

```
Add: 처음 1회만, 파일 복사 + 히스토리 포함
Pull: 필요할 때마다, 변경사항만 가져와서 병합
```

---

## 💡 실무 팁

### Tip 1️⃣: Squash 옵션

```bash
# ❌ 기본 (히스토리 많음)
git subtree add --prefix docs/curriculum \
  https://github.com/[USERNAME]/chatdox-curriculum.git main

# ✅ Squash (히스토리 압축)
git subtree add --prefix docs/curriculum \
  https://github.com/[USERNAME]/chatdox-curriculum.git main --squash

# ✅ Pull도 동일
git subtree pull --prefix docs/curriculum \
  https://github.com/[USERNAME]/chatdox-curriculum.git main --squash
```

**--squash의 효과:**
```
❌ 없이:
Platform에 curriculum의 모든 커밋 포함
├─ Add chapter 1 (curriculum)
├─ Add chapter 2 (curriculum)
├─ Add chapter 3 (curriculum)
├─ Update chapter 1 (curriculum)
└─ ...100개 이상의 커밋...

✅ --squash:
Platform에는 1개의 커밋으로 압축
└─ Add curriculum subtree (모든 파일 포함)
```

**우리 사용:** ✅ --squash 추천

---

### Tip 2️⃣: Subtree 폴더의 "약속"

```
Platform 개발자와의 약속:

📌 docs/curriculum/ 폴더는 읽기 전용
  - ✅ 파일 읽기
  - ❌ 파일 수정
  - ❌ 파일 삭제

📌 수정이 필요하면 curriculum 리포에서
  - cd d:\dev\chatdox-curriculum
  - 수정 후 Push
  - Platform에서 "git subtree pull"
```

**이 약속이 지켜지지 않으면?**
```
Platform에서 curriculum 파일을 수정
  ↓
Curriculum 리포와 Platform이 디스싱크
  ↓
다음 pull에서 충돌 발생!
  ↓
😱 헤드가 복잡해짐
```

---

### Tip 3️⃣: 충돌 해결

만약 실수로 Platform에서 curriculum 파일을 수정했다면:

```bash
# 변경사항 버리기
git checkout docs/curriculum/

# 또는 Stash
git stash

# 그 다음 pull
git subtree pull --prefix docs/curriculum \
  https://github.com/[USERNAME]/chatdox-curriculum.git main --squash
```

---

## 🤔 자주 묻는 질문

**Q: Platform에 curriculum이 이미 있으니 Git 용량이 크지 않나요?**  
A: 네, 조금 커집니다. 하지만 --squash 옵션으로 히스토리를 압축하면 관리 가능합니다.

**Q: Curriculum이 매우 자주 업데이트되면?**  
A: "git subtree pull" 명령어를 정기적으로 실행하면 됩니다. 일일 자동화도 가능 (GitHub Actions).

**Q: Subtree Pull 중 충돌이 나면 어떻게 하나요?**  
A: Platform에서 curriculum 파일을 수정했을 가능성 높음. 변경사항 버리고 pull하세요.

**Q: Submodule이 더 나은가요?**  
A: Submodule은 더 독립적이지만 복잡합니다. Subtree가 우리 목적(Platform 개발자가 편하게 사용)에 맞습니다.

**Q: Pull 말고 다른 방법이 있나요?**  
A: GitHub의 Webhook + Actions로 자동화 가능. (고급 주제)

---

## 📊 Git Subtree 명령어 정리

| 상황 | 명령어 | 어디서 | 역할 |
|------|--------|-------|------|
| 처음 추가 | `git subtree add` | Platform | Curriculum 전체 포함 |
| 정기 동기화 | `git subtree pull` | Platform | 최신 변경 가져오기 |
| 직접 푸시* | `git subtree push` | Platform | Platform 변경을 Curriculum으로 푸시 |

*주의: Subtree Push는 Platform에서 curriculum 파일을 수정했을 때만 사용. 일반적으로 하지 않음.

---

## 🎯 우리 프로젝트에서의 Subtree

### 현재 상태

```
chatdox-curriculum (Private)
  └─ GitHub에 푸시됨

chatdox-platform (Public)
  ├─ Rails 앱
  └─ docs/curriculum/
      └─ Subtree로 포함 (Git Subtree Add 완료)
         ├─ docs/
         ├─ prompts/
         ├─ QA/
         └─ SETUP/
```

### Platform 개발자의 경험

```
1️⃣ Platform 클론
$ git clone https://github.com/[USERNAME]/chatdox-platform.git
$ cd chatdox-platform
$ ls docs/curriculum/  ← Curriculum이 이미 있음!

2️⃣ 평소 사용
$ cat docs/curriculum/docs/04_landing_page.md
$ # 읽기만 함

3️⃣ Curriculum 업데이트가 발생했다면
$ git subtree pull --prefix docs/curriculum \
    https://github.com/[USERNAME]/chatdox-curriculum.git main --squash
$ # 최신 버전 동기화됨!
```

---

## 📚 관련 문서

- [SETUP/02_rails_platform_setup.md](../SETUP/02_rails_platform_setup.md) — 실제 Subtree Add 과정
- [QA/01_github_strategy.md](../QA/01_github_strategy.md) — 왜 2-repo 분리를 선택했나?
- [docs/03_dev_setup.md](../docs/03_dev_setup.md) — Git 기초 설정

---

## 💡 핵심 정리

```
Git Subtree의 핵심:

1. Add: 처음 1회만, Curriculum을 Platform에 복사
2. Use: Platform 개발자는 일반 파일처럼 사용
3. Pull: 필요할 때만, Curriculum 업데이트 동기화
4. Promise: docs/curriculum/ 폴더는 읽기 전용

"Pull만 하면 되나?" → NO
"첫 Add만 하면 되나?" → YES
"그 다음 Pull이 필요한가?" → 필요할 때만 YES
```

---

**마지막 업데이트:** 2026-07-09
