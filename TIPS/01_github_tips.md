---
title: "GitHub Repository 설정 가이드"
date: "2026-07-09"
category: "GitHub"
difficulty: "초급"
related: ["QA/01_github_strategy.md", "SETUP/01_github_repo_setup.md"]
---

# GitHub Repository 설정 가이드

`chatdox-curriculum` 리포지토리를 GitHub에 생성할 때 마주치는 선택사항들을 해결합니다.

---

## 🎯 이 팁을 읽어야 하는 경우

- GitHub에서 새 리포를 만들려고 한다
- Repository name, Description, License를 무엇으로 할지 모른다
- "Jumpstart your project with Copilot" 팝업이 뜬다
- .gitignore는 어떤 걸 선택해야 할지 궁금하다

---

## 📋 배경: Private vs Public 리포

**chatdox-curriculum (이 리포)**
- 공개 수준: **Private** 🔒
- 목적: 상품 (교과서) + 내부 설계
- 팀만 접근

**chatdox-platform (나중)**
- 공개 수준: **Public** 🌐
- 목적: Rails 구현 코드
- 누구나 접근

---

## ✅ 1. Repository Name

### 선택: `chatdox-curriculum`

**형식 규칙**
```
✅ 좋은 예
- chatdox-curriculum
- my-project-docs
- rails-saas-template

❌ 나쁜 예
- ChatdoxCurriculum (대문자)
- chatdox_curriculum (언더스코어)
- chatdoxcurriculum (너무 길어서 읽기 어려움)
```

**팁:**
- 모두 소문자
- 하이픈(-)으로 단어 구분
- 프로젝트 목적이 명확할 것

---

## ✅ 2. Repository Description

### 선택: `🚀 Learn by building: Full-stack SaaS curriculum with Ruby on Rails, Toss Payments, PostgreSQL`

**왜 이 설명을 선택했나?**

| 항목 | 이유 |
|------|------|
| **이모지 (🚀)** | GitHub 검색에서 눈에 띔 |
| **"Learn by building"** | 프로젝트의 핵심 철학 |
| **기술 스택 명시** | Rails, Toss Payments, PostgreSQL로 기술 검색에 최적화 |
| **160자 이내** | GitHub 권장 길이 (모바일에서도 전체 보임) |

**나쁜 예**
```
❌ Chatdox curriculum (너무 짧고 무엇인지 불명확)
❌ This is a complete guide to building a SaaS platform with Rails, Toss Payments, PostgreSQL and many other technologies... (너무 길음)
```

**팁:**
- 이모지는 1~2개만 (너무 많으면 스팸처럼 보임)
- 기술 키워드 3개 정도 포함
- 검색 트래픽을 고려해서 작성

---

## ✅ 3. Visibility (공개 수준)

### 선택: `Private` 🔒

**왜 Private?**

| 이유 | 설명 |
|------|------|
| **상품 보호** | 교과서가 수익화 대상이므로 공개하면 안됨 |
| **저작권 명시** | "No license" + Private = 명확한 소유권 |
| **내부 설계 보호** | prompts/, QA/ 폴더의 내부 논의 비공개 |
| **팀 집중도** | 필요한 사람만 접근 → 더 효율적 |

**체크리스트:**
- [x] Private 선택
- [x] 팀원들의 GitHub 계정 준비
- [x] Settings → Collaborators에서 권한 설정 예정

---

## ✅ 4. Add .gitignore

### 선택: `Python` (또는 스킵)

**왜 Python을 선택?**

이 리포에는:
- Markdown 문서 ✅
- 구조화된 폴더 ✅
- 코드는 없음 ❌

따라서 `.gitignore`가 거의 필요 없습니다.

**Python을 선택한 이유:**
- 나중에 다른 언어 코드가 추가될 가능성에 대비
- 혹은 테스트/스크립트를 Python으로 작성할 가능성

**다른 옵션**
```
Python       ← 추천 (일반적)
Ruby         ← 나중에 templates 폴더에 있을 수 있음
Node         ← 프론트엔드 추가 시 필요
None         ← 괜찮음, 나중에 수동으로 추가 가능
```

**참고:** `.gitignore`는 나중에 언제든 수정 가능합니다.

---

## ✅ 5. Add a License

### 선택: `None` (No license)

**왜 라이센스를 선택하지 않나?**

| 상황 | 라이센스 |
|------|---------|
| **chatdox-curriculum** (Private) | ❌ None (저작권 자동 보유) |
| **chatdox-platform** (Public) | ✅ MIT (나중에 추가) |
| **chatdox-templates** (Public) | ✅ MIT (나중에 추가) |

**Private 리포에서 "No license"의 의미:**
```
저작권 © 2026 Chatdox. All rights reserved.
```
- 자동으로 모든 권리를 저자가 보유
- 명시적 라이센스 불필요
- 상품으로 판매 가능

**나중에 Public으로 만들 때 (chatdox-platform):**
```
MIT License ← 가장 개발자 친화적
- 상업적 사용 허용
- 수정/배포 자유
- 저자의 책임은 제한
```

**팁:**
```yaml
# Private 리포: No license
# 이유: 상품 보호, 저작권 명시

# Public 리포: MIT License
# 이유: 개발자 커뮤니티 친화적
```

---

## ❌ 6. Jumpstart your project with Copilot

### 선택: `Skip` (스킵)

GitHub에서 이런 팝업이 보입니다:
```
Jumpstart your project with Copilot

Let GitHub Copilot help you initialize your project
[Use GitHub Copilot] [Skip this]
```

**왜 스킵하나?**

| 항목 | 상황 |
|------|------|
| **프로젝트 구조** | 이미 완전하게 설계됨 (docs/, prompts/, QA/, SETUP/) |
| **README** | 이미 작성됨 (프로젝트 개요) |
| **.gitignore** | 수동으로 선택함 |
| **초기 파일들** | 우리 규칙에 맞는 파일 필요 |

**만약 "Use Copilot"을 선택했다면:**
```
chatdox-curriculum/
├─ src/              ← 우리 구조와 다름
├─ tests/            ← 불필요
├─ .github/          ← 추가되지만 필요 없음
└─ README.md         ← 자동 작성 (일반적)
```

**결론:** 우리의 커스텀 구조가 훨씬 낫습니다. ✅

---

## 📋 최종 체크리스트

GitHub에서 새 리포 생성할 때:

- [ ] Repository name: `chatdox-curriculum`
- [ ] Description: `🚀 Learn by building: Full-stack SaaS curriculum with Ruby on Rails, Toss Payments, PostgreSQL`
- [ ] Visibility: `Private` 🔒
- [ ] Add .gitignore: `Python` (또는 선택 안함)
- [ ] Add a license: `None`
- [ ] Skip "Jumpstart with Copilot"
- [ ] [Create repository] 클릭

---

## 🤔 자주 묻는 질문

**Q: 나중에 설정을 바꿀 수 있나요?**  
A: 네! Settings 탭에서 언제든 수정 가능합니다. (Private ↔ Public 포함)

**Q: Description이 길면?**  
A: GitHub는 ~160자를 권장합니다. 더 길면 모바일에서 잘려요.

**Q: .gitignore를 잘못 선택했으면?**  
A: 괜찮습니다. 리포 생성 후 수동으로 수정하거나 새로 추가할 수 있어요.

**Q: 나중에 Public으로 바꾸면?**  
A: Settings → Change repository visibility → Public 선택. License도 그때 추가하세요.

**Q: Copilot을 사용하면 뭐가 나쁜데요?**  
A: 나쁜 건 아닌데, 불필요한 파일이 추가돼요. 깔끔하게 유지하려면 스킵 추천.

---

## 🔗 관련 문서

- [QA/01_github_strategy.md](../QA/01_github_strategy.md) — 2-Repository 분리 전략 배경
- [SETUP/01_github_repo_setup.md](../SETUP/01_github_repo_setup.md) — 실제 Git 명령어
- [docs/01_overview.md](../docs/01_overview.md) — 전체 프로젝트 구조

---

## 💡 핵심 정리

```
Repository: chatdox-curriculum
Description: 🚀 Learn by building: Full-stack SaaS curriculum with Ruby on Rails, Toss Payments, PostgreSQL
Visibility: Private 🔒
.gitignore: Python (또는 None)
License: None (저작권 자동 보유)
Copilot: Skip

→ 이대로 생성하고, 다음은 SETUP/01_github_repo_setup.md 따라 Git 명령어 실행!
```

---

**마지막 업데이트:** 2026-07-09
