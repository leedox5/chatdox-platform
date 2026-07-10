---
title: "Landing Page"
order: 1
status: "in-progress"
tech: "Rails/Tailwind CSS"
dependency: ["docs/04_landing_page.md"]
prompt: true
---

# 🚀 Platform 랜딩페이지 구현 프롬프트

이 문서는 **chatdox-platform Rails 앱**에 Tailwind CSS 기반 랜딩페이지를 구현하기 위한 프롬프트입니다.

---

## 📝 실행 순서

### 1단계: Rails 기본 홈페이지 제거 및 페이지 컨트롤러 생성

```bash
# 1. bin/rails server 종료 (Ctrl+C)
# 2. 제너레이터로 페이지 컨트롤러 생성
rails generate controller Pages home --skip-routes

# 3. 생성된 파일 확인
# app/controllers/pages_controller.rb
# app/views/pages/home.html.erb
```

### 2단계: 라우팅 설정

`config/routes.rb`에서 root 라우트 설정:
```ruby
Rails.application.routes.draw do
  root "pages#home"
end
```

### 3단계: PagesController 업데이트

`app/controllers/pages_controller.rb`:
```ruby
class PagesController < ApplicationController
  def home
    # 정적 랜딩페이지 - DB 조회 없음
  end
end
```

---

## 🎨 구현 가이드

### Tailwind CSS 클래스 스타일 가이드

| 섹션 | Tailwind 클래스 | 설명 |
|------|-----------------|------|
| Header | `sticky top-0 bg-white shadow-sm` | 스크롤 시 고정 |
| Hero | `py-24 bg-gradient-to-b from-blue-50 to-white` | 그라데이션 배경 |
| Section | `py-16 px-4 max-w-6xl mx-auto` | 섹션 기본 스타일 |
| 버튼 | `px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700` | 주요 CTA |
| 카드 | `p-6 border border-gray-200 rounded-lg hover:shadow-lg` | 박스/그리드 |
| 텍스트 | `text-gray-900 / text-gray-600 / text-gray-400` | 명암 단계 |

---

## 🎯 헤더 / 네비게이션

**로고** | **시작** | **가격** | **문서** | **커뮤니티** | **[로그인](#)**

---

## 🚀 Hero

<div align="center">

### 따라하면 서비스가 완성되는 웹서비스 구축 패키지

**누구나 단계별로 프로덕션 준비 완료된 SaaS를 직접 구현합니다.**

20개 완전한 문서 + GitHub 템플릿 코드 + 프로덕션 운영까지

**[7일 무료 체험 시작](#)** | [자세히 보기](#)**

*img1.jpg*

</div>

---

## 📚 완전한 커리큘럼 (20개 챕터)

### 📖 기본 개념 & 환경설정 (5개)

1. **채독스 전체 구조 이해** — 서비스 아키텍처, 기술 스택, 학습 로드맵
2. **Ruby on Rails 8.1 기초** — Rails 개념, MVC 패턴, 주요 기능
3. **개발 환경 세팅** — Git, 데이터베이스, 종속성 설치
4. **랜딩페이지 구축** — Tailwind CSS, 반응형 디자인
5. **프로젝트 구조 설계** — 모델, 컨트롤러, 뷰 조직화

### 💻 핵심 기능 구현 (11개)

6. **사용자 인증 (Devise)** — 회원가입, 로그인, 권한 관리
7. **데이터베이스 설계** — 스키마, 관계 설정, 마이그레이션
8. **핵심 기능 API 개발** — RESTful API, 응답 설계
9. **결제 시스템 연동** — Toss Payments / PortOne, 구독 관리, 결제 처리
10. **검색 기능 구현** — 전문 검색, 필터링, 성능 최적화
11. **이메일 알림 설정** — ActionMailer, 템플릿, 스케줄링
12. **파일 업로드 & 저장소** — ActiveStorage, S3 연동
13. **문서/콘텐츠 관리 시스템** — 마크다운 렌더링, 버전 관리
14. **사용자 대시보드 UI** — 구독 상태, 사용 현황, 설정
15. **테스트 작성 및 품질 보증** — RSpec, 통합 테스트
16. **Vercel/Railway 배포** — CI/CD 설정, 배포 프로세스

### 🔧 프로덕션 운영 & 최적화 (4개)

17. **모니터링 & 로깅** — Sentry, DataDog, 에러 추적
18. **보안 강화** — HTTPS, SQL Injection 방지, 암호화
19. **성능 최적화** — 캐싱, DB 쿼리 최적화, CDN
20. **마치며 & 다음 단계** — 커뮤니티 참여, 확장 기능 로드맵

---

## 🎁 상품 구성

### 기본형 + 프리미엄형 (2-Tier 구독)

비회원은 각 챕터의 샘플만 조회 가능하며, **구독 후 전체 문서와 코드에 접근**할 수 있습니다.

| 기능 | 기본형 | 프리미엄형 |
|------|--------|-----------|
| 20개 완전 문서 | ✅ | ✅ |
| 자체 서비스 내 마크다운 문서 | ✅ | ✅ |
| GitHub 템플릿 코드 | ✅ | ✅ |
| 이메일 지원 | ✅ (48시간) | ✅ (24시간 우선) |
| 커뮤니티 액세스 (Discord/Slack) | ❌ | ✅ |
| 우선 지원 | ❌ | ✅ |
| 향후 고급 기능 | ❌ | ✅ |

---

## 💳 가격

### 월 구독형

- **기본형**: $29/월 (연간 $199 - 36% 할인)
- **프리미엄형**: $79/월 (연간 $599 - 36% 할인)

**3일 무료 체험** — 신용카드 불필요, 언제든 취소 가능

---

## 🛠️ 기술 스택

SaaS 입문에 최적화된 스택으로, 서비스 운영 초기에 비용 부담이 적습니다.

- **Ruby on Rails 8.1** — 웹 프레임워크
- **Ruby 3.3** — 프로그래밍 언어
- **SQLite3 / PostgreSQL** — 데이터베이스
- **Devise** — 사용자 인증
- **Tailwind CSS** — 스타일링 & UI
- **Toss Payments / PortOne** — 선택형 결제 처리
- **ActiveStorage** — 파일 관리

---

## ❓ 자주 묻는 질문 (FAQ)

**Q. 개발 경험이 없는데 가능할까요?**
A. 네, 충분히 가능합니다! 모든 문서가 초보자를 기준으로 작성되었으며, 코드를 몰라도 단계별로 따라하면 동일한 결과물을 얻을 수 있습니다.

**Q. 문서는 어디서 조회하나요?**
A. 채독스 서비스 내 자체 마크다운 문서 시스템에서 제공됩니다. 외부 도구 가입 불필요하며, 구독하면 즉시 모든 문서와 코드에 접근 가능합니다.

**Q. 구독 후 언제든 취소할 수 있나요?**
A. 네, 언제든 자유롭게 취소 가능합니다. 다음 결제 날짜 전에 취소하면 이후 청구가 발생하지 않습니다.

**Q. 평생 접근이 가능한가요?**
A. 구독이 활성 상태인 동안 모든 문서와 코드에 접근할 수 있습니다. 구독 취소 후에는 접근 권한이 해제됩니다.

**Q. 업데이트는 얼마나 자주 되나요?**
A. 최신 Rails 버전, 보안 업데이트, 사용자 피드백을 반영하여 정기적으로 업데이트됩니다. 프리미엄 구독자에게는 업데이트 알림을 먼저 제공합니다.

---

## 📋 Footer

**회사 정보** | 대표: - | 사업자등록번호: - | 통신판매업신고: - | 주소: - | 이메일: -

[이용 약관](#) | [개인정보 처리 방침](#) | © 2026 채독스. All rights reserved.

---

## ✅ 구현 체크리스트

### 준비 단계
- [ ] `bin/rails server` 종료 (Ctrl+C)
- [ ] `rails generate controller Pages home --skip-routes` 실행
- [ ] `app/controllers/pages_controller.rb` 확인
- [ ] `app/views/pages/home.html.erb` 확인

### 코딩 단계
- [ ] `config/routes.rb`에 `root "pages#home"` 추가
- [ ] `app/controllers/pages_controller.rb`에 `home` 액션 구현
- [ ] `app/views/pages/home.html.erb` 작성
- [ ] `app/views/layouts/application.html.erb` 업데이트 (필요시)
- [ ] `app/views/shared/_header.html.erb` 생성 (부분 템플릿)
- [ ] `app/views/shared/_footer.html.erb` 생성 (부분 템플릿)
- [ ] 모든 섹션별 partial 생성

### 검증 단계
- [ ] `bin/rails server` 실행
- [ ] `http://localhost:3000` 접속
- [ ] 페이지 로드 확인 (500 에러 없음)
- [ ] 반응형 디자인 확인 (모바일/태블릿)
- [ ] 모든 링크 확인 (#로 시작하는 것 정상)
- [ ] Tailwind CSS 스타일 적용 확인

### 완료
- [ ] 모든 섹션이 화면에 표시됨
- [ ] 헤더/푸터 고정 잘 작동
- [ ] 모든 버튼/카드가 Tailwind 스타일링됨
- [ ] 모바일에서 리스폰시브 동작 확인

---

## 💡 구현 팁

1. **부분 템플릿(Partial) 활용**
   ```erb
   <%= render "shared/header" %>
   <%= render "landing/hero" %>
   <%= render "landing/curriculum" %>
   ```

2. **반응형 Tailwind 클래스**
   ```
   sm: (640px)   md: (768px)   lg: (1024px)   xl: (1280px)
   ```

3. **Git 관리**
   ```bash
   git add .
   git commit -m "feat: Add landing page with Tailwind CSS"
   git push origin main
   ```

---

## 📚 참고 자료

- **상세 구현**: [docs/04_landing_page.md](../docs/04_landing_page.md) 참고
- **Tailwind 문서**: https://tailwindcss.com/docs
- **Rails 뷰 가이드**: https://guides.rubyonrails.org/action_view_overview.html

---

**마지막 업데이트:** 2026-07-09

