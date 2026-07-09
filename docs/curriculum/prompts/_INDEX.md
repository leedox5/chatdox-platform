---
title: "프롬프트 INDEX"
order: 0
status: completed
tech: "관리 문서"
dependency: []
---

# 📚 프롬프트 INDEX

**SaaS 랜딩페이지 및 핵심 페이지의 UI/UX 프롬프트 관리**

---

## 📊 전체 진행도

| # | 페이지명 | 설명 | 상태 | 기술 스택 |
|---|---------|------|------|---------|
| 01 | Landing Page | 메인 랜딩페이지 (Draft) | ✅ 완료 | Rails/Tailwind |
| 01-R1 | Landing Page Revision 1 | Nav 링크 → Dummy 페이지 연결 | ✅ 완료 | Rails/Tailwind |
| 02 | Docs Preview | 문서 열람 (사이드바 + Markdown) | ✅ 완료 | Rails/Redcarpet |
| 02-R1 | Docs Preview R1 | 20챕터 전체 목록 + 파일 존재 여부 자동 체크 | ✅ 완료 | Rails/Redcarpet |
| 03 | Auth (Signup/Login) | 회원가입/로그인 페이지 | ⏳ 예정 | Rails/Devise |
| 03 | Pricing | 가격 플랜 페이지 | ⏳ 예정 | Rails/Tailwind |
| 04 | Dashboard | 사용자 대시보드 | ⏳ 예정 | Rails/Tailwind |
| 05 | Documentation | 문서 열람 페이지 | ⏳ 예정 | Rails/Markdown |
| 06 | Settings | 사용자 설정 페이지 | ⏳ 예정 | Rails/Tailwind |
| 07 | Community | 커뮤니티 페이지 (선택사항) | ⏳ 예정 | Rails/Discord API |
| 08 | Admin Dashboard | 관리자 대시보드 | ⏳ 예정 | Rails/Charts.js |

---

## 🏗️ 페이지별 설명

### ✅ 01 Landing Page (구현 진행중)
**파일:** `01_landing_page.md`
- 실행 순서 명시 (절차적 가이드)
- Tailwind CSS 클래스 스타일 가이드 표
- 구현 체크리스트
- 부분 템플릿(Partial) 활용법
- 참고 자료 링크

**프롬프트 특징:**
- Rails 기본 홈페이지 삭제 및 재생성
- `PagesController#home` 구현
- Tailwind CSS 반응형 디자인
- 8개 섹션 구현

**상세:** [01_landing_page.md](01_landing_page.md)

---

### ⏳ 02 Auth (회원가입/로그인)
**파일:** `02_auth.md` (미작성)
- 회원가입 폼
- 로그인 폼
- 비밀번호 재설정
- 이메일 인증

**의존성:** 없음 (독립)

---

### ⏳ 03 Pricing
**파일:** `03_pricing.md` (미작성)
- 가격 플랜 상세
- 기본형/프리미엄형 비교
- FAQ 섹션
- CTA 버튼

**의존성:** 없음 (독립)

---

### ⏳ 04 Dashboard
**파일:** `04_dashboard.md` (미작성)
- 구독 상태 표시
- 사용 현황 (차트)
- 다운로드 문서 목록
- 빠른 접근 링크

**의존성:** 02_auth (로그인 필수)

---

### ⏳ 05 Documentation
**파일:** `05_documentation.md` (미작성)
- 20개 챕터 목록
- 마크다운 뷰어
- 검색 기능
- 토글 네비게이션

**의존성:** 02_auth (로그인 필수), 04_dashboard

---

### ⏳ 06 Settings
**파일:** `06_settings.md` (미작성)
- 프로필 설정
- 구독 관리/취소
- 이메일 알림 설정
- 보안 설정

**의존성:** 02_auth (로그인 필수)

---

### ⏳ 07 Community (선택사항)
**파일:** `07_community.md` (미작성)
- Discord/Slack 초대 링크
- 커뮤니티 안내
- 피드백 폼

**의존성:** 02_auth (선택적)

---

### ⏳ 08 Admin Dashboard
**파일:** `08_admin_dashboard.md` (미작성)
- 사용자 관리
- 결제 통계
- 콘텐츠 관리
- 시스템 모니터링

**의존성:** 02_auth (관리자 권한 필수)

---

## 📅 권장 구현 순서

1️⃣ **01_landing_page** ✅ (완료)
2️⃣ **02_auth** (회원가입/로그인 → 다른 기능 전제)
3️⃣ **03_pricing** (독립, 빠른 완료 가능)
4️⃣ **04_dashboard** (인증 이후)
5️⃣ **05_documentation** (코어 기능)
6️⃣ **06_settings** (부가 기능)
7️⃣ **07_community** (선택사항)
8️⃣ **08_admin_dashboard** (마지막)

---

## 🔗 의존성 맵

```
Landing Page (01) ─┐
                   ├─→ Auth (02) ─┬─→ Dashboard (04) ─→ Documentation (05)
                   │              ├─→ Settings (06)
                   │              └─→ Admin Dashboard (08)
                   │
Pricing (03) ─────┘
```

---

## 💾 사용 방법

각 프롬프트 파일:
- **개요**: 페이지의 목적과 기본 구조
- **Design Guidelines**: 색상, 폰트, 컴포넌트 규칙
- **구현 체크리스트**: 필수 요소 확인

**예시 구조:**
```markdown
## 📋 개요
...

## 🎨 Design Guidelines
- 색상: 
- 타이포그래피:
- 레이아웃:

## ✅ 구현 체크리스트
- [ ] 요소 1
- [ ] 요소 2
```

---

## 🔄 업데이트 이력

| 날짜 | 변경사항 |
|------|---------|
| 2026-07-09 | INDEX 생성, 01_landing_page 완료 |

