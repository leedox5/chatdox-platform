# 💡 TIPS: 개발자 노하우 모음

개발 과정에서 나눈 결정, 선택 이유, 그리고 실무 팁을 문서화합니다.

**대상 독자:** 개발 팀, 새로운 팀원, 의사결정 배경이 궁금한 사람

---

## 📚 목차

### GitHub & 저장소

| # | 제목 | 주제 | 작성일 |
|---|------|------|-------|
| [01](01_github_tips.md) | GitHub Repository 설정 가이드 | Description, License, .gitignore 선택 | 2026-07-09 |
| [02](02_git_subtree.md) | Git Subtree 개념과 실무 활용 | Subtree 원리, Pull 타이밍, 주의사항 | 2026-07-09 |
| [03](03_subtree_collaboration.md) | Subtree 협업 규칙 & 읽기 전용 정책 | Platform/Curriculum 분리, 변경 요청 방법 | 2026-07-09 |
| 04 | (예정) Git Workflow 팁 | Commit 메시지, Branch 전략 | - |
| 05 | (예정) SSH vs HTTPS | 인증 방식 선택 | - |

### Rails & 개발

| # | 제목 | 주제 |
|---|------|------|
| 04 | (예정) Rails Gem 선택 기준 | Devise vs Pundit 등 |
| 05 | (예정) Database 마이그레이션 | SQLite3 vs PostgreSQL |

### 배포 & 프로덕션

| # | 제목 | 주제 |
|---|------|------|
| 06 | (예정) Vercel vs Railway | 배포 플랫폼 비교 |
| 07 | (예정) 환경 변수 관리 | .env 보안 실무 |

---

## 🎯 TIPS의 역할

| 문서 | 목적 | 내용 |
|------|------|------|
| **docs/** | 교과서 | "어떻게 하는가" |
| **prompts/** | 설계 | "무엇을 만들 것인가" |
| **QA/** | 의사결정 | "왜 이것을 선택했는가" |
| **SETUP/** | 프로세스 | "단계별 가이드" |
| **TIPS/** | 노하우 | "왜 이렇게 하는가" (심화) |

### TIPS는 언제 읽나?

- ✅ 비슷한 상황에서 같은 선택을 할 때
- ✅ "이 방식이 최선인가?" 의심할 때
- ✅ 팀원과 논의할 때
- ✅ 새로운 팀원을 온보딩할 때

---

## 🔍 빠른 검색

### GitHub & 저장소
- Repository Description은 뭐라고? → [TIPS/01](01_github_tips.md#repository-description)
- License는 어떤 걸 선택? → [TIPS/01](01_github_tips.md#license-선택)
- Copilot "Jumpstart" 기능은? → [TIPS/01](01_github_tips.md#jumpstart-your-project-with-copilot)
- Git Subtree가 뭔가요? → [TIPS/02](02_git_subtree.md)
- Subtree Pull은 언제 필요한가? → [TIPS/02](02_git_subtree.md#-pull만-하면-되나-질문에-대한-답)
- Platform에서 curriculum 수정할 수 있나? → [TIPS/03](03_subtree_collaboration.md#-규칙-docscurriculum은-읽기-전용)
- Curriculum 변경을 어떻게 요청하나? → [TIPS/03](03_subtree_collaboration.md#-변경-요청하기-3가지-방법)

### 기술 선택
- Ruby on Rails를 선택한 이유? → [QA/01_github_strategy.md](../QA/01_github_strategy.md)
- SQLite3 vs PostgreSQL? → docs/03_dev_setup.md

---

## 📝 TIPS 작성 규칙

각 TIPS 문서는 다음 구조를 따릅니다:

```markdown
---
title: "제목"
date: "2026-07-09"
category: "GitHub|Rails|Deploy|Performance"
difficulty: "초급|중급|고급"
related: ["QA/01_github_strategy.md", "docs/03_dev_setup.md"]
---

# 제목

## 🎯 이 팁을 읽어야 하는 경우

- 상황 A
- 상황 B

## 📋 배경 지식

왜 이런 선택을 해야 하는가?

## ✅ 해결책

구체적인 방법

## 🤔 자주 묻는 질문

Q: ...?  
A: ...

## 🔗 관련 자료

- [문서명](경로)
```

---

## 💬 팀 논의

새로운 TIPS를 추가하려면?

1. 비슷한 상황에서 팀이 고민한 주제
2. 여러 옵션이 있었고 선택한 경험
3. "이건 좋은 팁이다!" 하는 내용

Issues 또는 팀 미팅에서 제안하세요!

---

**마지막 업데이트:** 2026-07-09
