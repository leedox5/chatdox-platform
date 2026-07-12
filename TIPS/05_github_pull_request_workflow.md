---
title: "GitHub Pull Request 생성·리뷰·승인 가이드"
date: "2026-07-10"
category: "GitHub"
difficulty: "초급"
related: ["TIPS/01_github_tips.md", "TIPS/03_subtree_collaboration.md", "QA/01_github_strategy.md"]
---

# GitHub Pull Request 생성·리뷰·승인 가이드

작업 브랜치의 변경사항을 PR로 공유하고, 리뷰와 승인을 거쳐 안전하게 기준 브랜치에 병합하는 방법을 설명합니다.

---

## 🎯 이 팁을 읽어야 하는 경우

- `main`에 직접 push하지 않고 협업하고 싶다
- 처음으로 PR을 생성하거나 리뷰해야 한다
- `Approve`, `Request changes`, `Comment`의 차이가 궁금하다
- 승인받았는데도 병합할 수 없는 이유를 알고 싶다
- 팀의 PR 승인 규칙을 정하려고 한다

---

## 📋 Pull Request란?

PR은 **작업 브랜치의 변경사항을 기준 브랜치에 반영해 달라는 요청**입니다.

```text
작업 브랜치 생성 → 수정·Commit·Push → PR 생성
→ 리뷰·수정·승인 → CI 통과 → main에 Merge
```

PR에서는 변경 파일과 이유, 테스트 결과, 리뷰·승인, CI 상태와 관련 Issue를 한곳에서 확인할 수 있습니다.

---

## ✅ 1단계: 작업 브랜치 만들기

```bash
git switch main
git pull origin main
git switch -c feature/login

# 코드 수정 후
git add .
git commit -m "feat: 이메일 로그인 기능 추가"
git push -u origin feature/login
```

| 목적 | 브랜치 이름 예시 |
|------|------------------|
| 기능 추가 | `feature/login` |
| 버그 수정 | `fix/payment-error` |
| 문서 수정 | `docs/pr-guide` |
| 리팩터링 | `refactor/user-service` |

> 하나의 브랜치와 PR에는 가능한 한 하나의 목적만 담습니다. PR이 작을수록 리뷰가 빠르고 정확해집니다.

---

## ✅ 2단계: PR 생성하기

### GitHub 웹에서 생성

1. 저장소의 **Pull requests** 탭에서 **New pull request**를 선택합니다.
2. `base`에는 변경이 들어갈 브랜치(예: `main`), `compare`에는 작업 브랜치(예: `feature/login`)를 지정합니다.
3. `Files changed`에서 의도하지 않은 파일이 포함되지 않았는지 확인합니다.
4. 제목과 설명을 작성하고 **Create pull request**를 선택합니다.

브랜치 방향을 반대로 선택하지 않도록 `base ← compare` 관계를 꼭 확인합니다.

### PR 설명 템플릿

```markdown
## 작업 내용

- 이메일과 비밀번호 로그인 구현
- 로그인 실패 메시지와 API 테스트 추가

## 테스트 방법

1. 테스트 계정으로 로그인
2. 잘못된 비밀번호 입력
3. 정상 로그인과 오류 메시지 확인

## 관련 이슈

Closes #123

## 체크리스트

- [ ] 로컬 테스트를 통과했다
- [ ] 불필요한 파일이 포함되지 않았다
- [ ] 필요한 문서를 함께 수정했다
```

`Closes #123` 또는 `Fixes #123`은 PR 병합 시 연결된 Issue를 자동으로 닫습니다.

### GitHub CLI로 생성

```bash
gh pr create \
  --base main \
  --head feature/login \
  --title "feat: 이메일 로그인 기능 추가" \
  --body "로그인 기능과 관련 테스트를 추가했습니다."
```

대화형 작성은 `gh pr create`, 작업 중인 PR은 `gh pr create --draft`를 사용합니다. 작업이 끝나면 **Ready for review**로 전환합니다.

---

## ✅ 3단계: 리뷰 요청하기

PR 오른쪽의 **Reviewers**에서 리뷰할 사람이나 팀을 선택합니다. 요청할 때는 다음을 알려줍니다.

- 무엇을, 왜 변경했는가?
- 특히 확인해야 할 코드는 어디인가?
- 어떻게 실행하고 테스트하는가?
- 관련 Issue나 설계 문서는 무엇인가?

---

## ✅ 4단계: 리뷰하고 승인하기

리뷰어는 **Files changed**에서 변경사항을 확인합니다. 특정 줄의 `+` 버튼으로 코드에 직접 의견을 남기고, **Review changes**에서 상태를 선택한 후 **Submit review**를 누릅니다.

| 상태 | 의미 | 사용 시점 |
|------|------|-----------|
| **Comment** | 의견만 전달 | 질문이나 선택적 제안이 있을 때 |
| **Approve** | 병합에 동의 | 문제가 없고 병합해도 될 때 |
| **Request changes** | 수정 요청 | 병합 전 반드시 고칠 문제가 있을 때 |

### 리뷰 체크리스트

- [ ] 요구사항을 정확히 구현했다
- [ ] 예상하지 못한 부작용이 없다
- [ ] 테스트가 변경사항을 충분히 검증한다
- [ ] 보안, 권한, 개인정보 문제가 없다
- [ ] 이름과 구조가 이해하기 쉽다
- [ ] PR 범위를 벗어난 변경이 섞이지 않았다

좋은 댓글은 문제 위치, 발생 조건, 개선 방향을 함께 설명합니다.

---

## ✅ 5단계: 리뷰 의견 반영하기

같은 작업 브랜치에서 수정한 뒤 다시 push합니다.

```bash
git add .
git commit -m "fix: PR 리뷰 내용 반영"
git push
```

기존 PR이 자동으로 업데이트되므로 새 PR은 필요 없습니다. 댓글에 수정 내용을 답변하고, 처리된 대화를 **Resolve conversation**으로 닫은 뒤 재검토를 요청합니다.

> 설정에 따라 승인 후 새 커밋을 push하면 기존 승인이 취소되어 재승인이 필요할 수 있습니다.

---

## ✅ 6단계: 병합하기

- [ ] 필요한 승인 수를 충족했다
- [ ] GitHub Actions 등 필수 CI 검사를 통과했다
- [ ] 기준 브랜치와 충돌이 없다
- [ ] 필수 리뷰 대화를 모두 해결했다
- [ ] 작업 브랜치가 기준 브랜치의 최신 상태를 반영했다

| 방식 | 특징 | 추천 상황 |
|------|------|-----------|
| **Create a merge commit** | 작업 커밋과 병합 커밋을 유지 | 브랜치 단위 이력을 보존할 때 |
| **Squash and merge** | PR의 커밋을 하나로 합침 | 기능 단위로 이력을 간결하게 관리할 때 |
| **Rebase and merge** | 커밋을 기준 브랜치 위에 재배치 | 선형 이력과 개별 커밋을 유지할 때 |

작은 기능 PR에는 `Squash and merge`가 편리하지만 팀의 Git 정책을 우선합니다.

```bash
# 병합 후 브랜치 정리
git switch main
git pull origin main
git branch -d feature/login
git push origin --delete feature/login
```

---

## 🔐 승인을 필수로 만드는 방법

PR 생성만으로 승인이 강제되지는 않습니다. 관리자가 `main`에 **Ruleset** 또는 **Branch protection rule**을 설정해야 합니다.

1. 저장소 **Settings**로 이동합니다.
2. **Rules**에서 **Rulesets** 또는 **Branches**를 선택합니다.
3. `main`을 대상으로 규칙을 생성합니다.
4. 팀 정책에 맞는 조건을 활성화합니다.

### 권장 규칙

```text
main 직접 push 금지
Pull Request를 통한 변경만 허용
최소 1명 이상의 승인 필수
필수 CI 상태 검사 통과
미해결 리뷰 대화 해결
필요하면 새 커밋 추가 시 이전 승인 취소
필요하면 CODEOWNERS 승인 필수
```

- PR 작성자는 자기 PR을 승인할 수 없습니다.
- 어떤 승인이 필수 승인 수에 포함되는지는 권한과 규칙에 따라 달라집니다.
- 보호 규칙이 없으면 `Request changes`가 병합을 기술적으로 차단하지 않을 수 있습니다.
- 관리자 우회 허용 여부도 저장소 규칙에서 결정합니다.

---

## 💡 실전 팁

1. 로그인, 회원가입, 권한처럼 독립된 변경은 각각 작은 PR로 나눕니다.
2. 리뷰 요청 전 `Files changed`를 직접 읽고 임시 코드·파일·비밀정보를 확인합니다.
3. CI 실패 원인을 먼저 해결하고, 환경 문제라면 PR에 이유를 남깁니다.
4. PR 범위를 벗어난 개선사항은 새 Issue로 분리합니다.

---

## 🤔 자주 묻는 질문

**Q: 승인받았는데 Merge 버튼이 비활성화되어 있나요?**  
A: 승인 수, 필수 CI, 충돌, 최신 브랜치 여부, 미해결 대화와 CODEOWNERS 조건을 확인하세요.

**Q: PR 생성 후 코드를 더 수정해도 되나요?**  
A: 같은 브랜치에 push하면 기존 PR이 자동으로 갱신됩니다.

**Q: 사소한 수정도 재승인이 필요한가요?**  
A: 새 커밋 추가 시 승인을 취소하도록 설정했다면 재승인이 필요합니다.

**Q: 누가 Merge해야 하나요?**  
A: 팀 규칙에 따릅니다. 작성자가 조건 충족 후 병합하거나 리뷰어·관리자가 최종 확인할 수 있습니다.

---

## 📚 관련 문서

- [TIPS/01_github_tips.md](01_github_tips.md) — GitHub Repository 설정 가이드
- [TIPS/03_subtree_collaboration.md](03_subtree_collaboration.md) — Subtree 협업과 변경 요청 규칙
- [QA/01_github_strategy.md](../QA/01_github_strategy.md) — 저장소 운영 전략의 배경
- [GitHub Docs: Creating a pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request)
- [GitHub Docs: Reviewing proposed changes](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/reviewing-proposed-changes-in-a-pull-request)
- [GitHub Docs: Merging a pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/merging-a-pull-request)

---

## 🎯 핵심 정리

```text
브랜치 생성 → 수정·Push → PR 생성 → 리뷰·피드백 반영
→ 승인·CI 확인 → Merge

승인을 강제하려면 Ruleset 또는 Branch protection 설정이 필요합니다.
```

---

**마지막 업데이트:** 2026-07-10
