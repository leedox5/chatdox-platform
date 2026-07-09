# 📚 Chatdox: Chat-GPT + Leedox

## 완전 문서화된 SaaS 구현 교육 플랫폼

> **프로젝트 철학:** 누구나 실제 SaaS를 처음부터 끝까지 구현하며 배울 수 있도록, 
> 모든 결정과 과정을 문서화하고 공유한다.

---

## 🎯 프로젝트 개요

**Chatdox**는 다음의 결합입니다:

- 🤖 **Chat-GPT**: AI 기반 문서 분석
- 📖 **Leedox**: Lees + Documentation (전문가 지식 + 상세 문서)

### 목표

1. **완전 교육 과정**: 20개 챕터로 SaaS 구현의 모든 과정 기록
2. **투명한 결정**: 왜 이렇게 했는지 설명 (QA 시리즈)
3. **재현 가능**: 다른 개발자도 동일하게 따라 할 수 있는 가이드
4. **프로덕션 준비**: 실제 배포 가능한 완전한 애플리케이션

---

## 📂 저장소 구조

```
chatdox-curriculum/  (이 리포 - PRIVATE)
├─ docs/             📚 상품 핵심: 20개 챕터
│  ├─ 01_overview.md                    ✅ 전체 아키텍처 이해
│  ├─ 02_rails_basics.md                ✅ Rails 기초
│  ├─ 03_dev_setup.md                   ✅ 개발 환경 설정
│  ├─ 04_landing_page.md                ✅ 랜딩 페이지 구현
│  └─ 05-20_*.md                        ⏳ 진행 중...
│
├─ prompts/          🎨 UI/UX 설계 (내부용)
│  ├─ _INDEX.md                         ✅ 8개 페이지 계획
│  └─ 01_landing_page.md                ✅ 완료
│
├─ QA/               💡 의사결정 기록
│  ├─ README.md                         ✅ Q&A 시스템
│  └─ 01_github_strategy.md             ✅ 2-repo 분리 전략
│
├─ SETUP/            🛠️ 개발자 가이드
│  ├─ README.md                         ✅ SETUP 목차
│  ├─ 01_github_repo_setup.md           ✅ GitHub 리포 생성
│  └─ 02_rails_platform_setup.md        ✅ Rails 앱 생성 및 실행
│
├─ TIPS/             💡 개발자 노하우
│  ├─ README.md                         ✅ TIPS 목차
│  └─ 01_github_tips.md                 ✅ GitHub 설정 가이드
│
└─ README.md         ← 현재 문서 (프로젝트 개요)
```

### 폴더별 역할

| 폴더 | 목적 | 공개 여부 | 대상 |
|------|------|---------|------|
| **docs/** | 상품 핵심 - 20개 챕터 교과서 | Private | 학생 (구독자) |
| **prompts/** | UI/UX 설계 및 내부 가이드 | Private | 내부 팀 |
| **QA/** | 의사결정 기록 및 기술 선택 근거 | Private | 개발 팀 |
| **SETUP/** | 개발 팀용 셋업 가이드 | Private | 개발자 |

---

## 🏗️ 아키텍처 개요

### 3가지 GitHub 리포지토리 전략

```
1. chatdox-curriculum (PRIVATE) ← 현재 위치
   목적: 상품 (교과서) + 내부 설계
   
2. chatdox-platform (PUBLIC) - Rails 애플리케이션
   목적: 실제 구현
   통합: curriculum을 Git Subtree로 포함
   
3. chatdox-templates (PUBLIC) - 선택사항
   목적: 각 챕터별 완성 코드 스냅샷
```

**상세 설명:** [QA/01_github_strategy.md](QA/01_github_strategy.md)

### 기술 스택

| 계층 | 기술 | 버전 | 역할 |
|------|------|------|------|
| **Backend** | Rails | 8.1.3 ✅ | 웹 애플리케이션 프레임워크 |
| **Language** | Ruby | 3.4.9 ✅ | 서버 사이드 언어 |
| **Frontend** | ERB + Tailwind CSS | Latest ✅ | UI/UX 구현 |
| **Database** | SQLite3 → PostgreSQL | Latest | 데이터 저장 |
| **Auth** | Devise | Latest | 사용자 인증 |
| **Payment** | Toss Payments | API v2 | 결제 처리 |
| **Storage** | ActiveStorage + S3 | Latest | 파일 저장소 |
| **Monitoring** | Sentry | Latest | 에러 추적 |
| **Deployment** | Vercel / Railway | Latest | 프로덕션 배포 |

---

## 📊 진행 상황

### 목표: 20개 챕터 완성

```
🟢 Phase 1: 기초 (5개)
   ✅ 01_overview.md           - 전체 아키텍처
   ✅ 02_rails_basics.md       - Rails 개념
   ✅ 03_dev_setup.md          - 환경 설정
   ✅ 04_landing_page.md       - 랜딩 페이지
   ⏳ 05_project_structure.md  - 프로젝트 구조 (예정)

🟡 Phase 2: 구현 (11개)
   ⏳ 06-16: 인증, DB, API, 결제, 검색, 이메일, 파일, CMS, 대시보드, 테스트, 배포

🔴 Phase 3: 운영 (4개)
   ⏳ 17-20: 모니터링, 보안, 성능, 결론
```

**현재 진행률:** 4/20 **20%** (curriculum 챕터) + chatdox-platform 생성 및 실행 ✅

---

## 🚀 빠른 시작

### 1단계: 이 리포 클론 (개발자/학생용)

```bash
git clone git@github.com:[USERNAME]/chatdox-curriculum.git
cd chatdox-curriculum
```

### 2단계: 문서 읽기 순서

**첫 학습자라면:**
1. [docs/01_overview.md](docs/01_overview.md) — 전체 그림 이해 (30분)
2. [docs/02_rails_basics.md](docs/02_rails_basics.md) — Rails 배우기 (1시간)
3. [docs/03_dev_setup.md](docs/03_dev_setup.md) — 환경 설정 (30분)
4. [docs/04_landing_page.md](docs/04_landing_page.md) — 첫 구현 (2시간)

### 3단계: 자신의 Rails 앱 생성

```bash
# 설정 가이드 참고
cat SETUP/01_github_repo_setup.md
```

### 4단계: chatdox-platform Rails 앱 생성

[SETUP/02_rails_platform_setup.md](SETUP/02_rails_platform_setup.md) 참고

```bash
cd ../
rails new chatdox-platform --css tailwind --database sqlite3 --skip-test
cd chatdox-platform
```

### 5단계: Git Subtree로 통합 (완료) ✅

```bash
git subtree add --prefix docs/curriculum \
  https://github.com:[USERNAME]/chatdox-curriculum.git main
```

---

## 💡 핵심 철학

### 왜 이렇게 만들었나?

#### 1️⃣ **완전성**
- 단순 튜토리얼 ❌
- 실제 SaaS 전체 구현 ✅
- 배포 → 모니터링까지 모두 포함

#### 2️⃣ **투명성**
- "왜?"를 문서화 (QA 시리즈)
- 기술 선택의 근거 명확
- 팀원이 쉽게 이해 가능

#### 3️⃣ **재현성**
- Step-by-step 가이드
- 플랫폼별 설정 (Windows/macOS/Linux)
- 실제 코드로 검증됨

#### 4️⃣ **소유권**
- 배운 코드가 본인 것
- 단순 튜토리얼 아님
- 자신의 SaaS로 확장 가능

---

## 🎓 학습 철학

이 프로젝트는 다음을 믿습니다:

> **직접 만들기가 최고의 학습이다.**

✅ 보기만 하는 튜토리얼? NO  
✅ 실제로 손으로 따라하는 교과서? YES  
✅ 에러 만나고, 해결하고, 배운다? YES  
✅ 완성된 SaaS를 자신의 것으로 확장? YES

---

## 📖 문서 체계

### 계층 구조

```
README.md (프로젝트 개요) ← 현재
   ↓
docs/01_overview.md (아키텍처 소개)
   ↓
docs/02-04.md (기초 3개)
   ↓
docs/05-16.md (구현 12개)
   ↓
docs/17-20.md (운영 4개)
```

### YAML 프론트매터 규칙

모든 문서는 메타데이터를 포함합니다:

```yaml
---
title: "문서 제목"
order: 1
status: "완료|진행중|계획|검토"
tech: "Rails, PostgreSQL, Devise"
dependency: "01_overview.md"
---
```

---

## 🔗 관련 리포지토리

| 리포 | 공개 | 상태 | 목적 |
|------|------|------|------|
| [chatdox-curriculum](https://github.com/[USERNAME]/chatdox-curriculum) | Private | 🟢 진행중 | 교과서 + 설계 (현재) |
| [chatdox-platform](https://github.com/[USERNAME]/chatdox-platform) | Public | 🟡 예정 | Rails 구현 |
| [chatdox-templates](https://github.com/[USERNAME]/chatdox-templates) | Public | 🔴 예정 | 챕터별 완성 코드 |

---

## 🎁 제품 구성

### Chatdox 구독 (2-Tier)

이 리포의 **docs/** 폴더 내용이 상품입니다.

| 기능 | 기본형 | 프리미엄형 |
|------|--------|-----------|
| 20개 완전 문서 | ✅ | ✅ |
| 마크다운 렌더링 | ✅ | ✅ |
| GitHub 템플릿 코드 | ✅ | ✅ |
| 이메일 지원 | ✅ (48시간) | ✅ (24시간 우선) |
| 커뮤니티 (Discord) | ❌ | ✅ |
| 우선 지원 | ❌ | ✅ |

**가격:**
- 기본형: $29/월
- 프리미엄형: $79/월

---

## 📋 기여 및 피드백

### 이 리포에 참여하려면?

1. **오류 발견?**
   → Issues에서 제보 (Private 리포이므로 팀만 접근)

2. **더 나은 설명?**
   → Pull Request 또는 Issues에서 제안

3. **새로운 챕터?**
   → 팀 논의 후 추가

### 커뮤니티

- 📧 이메일: [contact@chatdox.com]
- 💬 Discord: [예정]
- 🐛 버그: Issues 탭

---

## ❓ FAQ

**Q: 이 코드를 내 프로젝트에 사용해도 되나요?**  
A: 네! 이것이 바로 목표입니다. 배운 내용으로 자신의 프로젝트를 만드세요.

**Q: 얼마나 자주 업데이트되나요?**  
A: 매주 새로운 챕터 추가 예정입니다. (현재 진행 중)

**Q: Rails를 모르는데 시작할 수 있나요?**  
A: 네! 02_rails_basics.md부터 모든 개념을 설명합니다.

**Q: 다른 프레임워크(Next.js, FastAPI)로 할 수 있나요?**  
A: 현재는 Rails만 지원합니다. 다른 프레임워크는 추후 계획 중입니다.

**Q: 구독을 취소하면 어떻게 되나요?**  
A: 활성 구독 중에만 docs/ 폴더의 전체 문서에 접근할 수 있습니다. 취소 후에는 접근 권한이 해제됩니다.

---

## 📜 라이센스 및 저작권

이 프로젝트는 **교육 목적**으로 운영됩니다:

- **docs/**: 저작권 보유 (구독 서비스 상품)
- **prompts/**: 내부 설계 (비공개)
- **QA/**: 의사결정 기록 (팀 공유)
- **SETUP/**: 개발 가이드 (팀 공유)

구독자는 상업적 목적으로 학습한 코드를 사용할 수 있습니다.

---

## ✨ 감사의 말

이 프로젝트는 다음에 영감을 받았습니다:

- Ruby on Rails 커뮤니티
- 오픈소스 교육 철학
- 실무 SaaS 개발 경험

---

<div align="center">

**Chatdox - 누구나 SaaS를 직접 구현할 수 있다** ✨

[📖 커리큘럼 보기](docs/01_overview.md) · [🛠️ 설정 가이드](SETUP/README.md) · [💡 의사결정](QA/README.md) · [🎨 설계](prompts/_INDEX.md)

---

마지막 업데이트: 2026-07-09

</div>
