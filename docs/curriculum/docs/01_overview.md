# 1. 채독스 전체 구조 이해

> 이 챕터에서는 채독스가 어떤 서비스인지, 어떤 기술로 이루어져 있는지,
> 그리고 앞으로 20개 챕터를 통해 무엇을 만들게 되는지 전체 그림을 이해합니다.

---

## 📌 채독스란?

채독스는 **Chat-GPT + Leedox**의 합성어로, AI Assistant를 활용한 SaaS 서비스입니다.

이 프로젝트를 직접 구현하면서 다음을 경험하게 됩니다:

- Ruby on Rails로 **실전 SaaS 서비스** 구축
- 사용자 인증, 결제, 구독 관리 등 **비즈니스 핵심 기능** 구현
- 배포부터 모니터링까지 **프로덕션 운영** 경험

---

## 💼 비즈니스 모델

### 구독 정책

채독스는 **SaaS(Software as a Service)** 모델로 운영됩니다.

| 구분 | 비로그인 | Trial (7일) | Subscriber (월간) |
|------|---------|-----------|------------------|
| **상태** | Guest | 로그인 후 7일 이내 | 월 $9.99 결제 중 |
| **문서 접근** | 1-2장만 | 1-5장 | 1-20장 전체 |
| **대시보드** | ❌ | ✅ | ✅ |
| **가격** | 무료 | 무료 | $9.99/월 |
| **계약** | N/A | 자동 | 월간 (자동갱신) |

> 자세한 비즈니스 모델, 수익 계산, 가격 전략은 `internal/BUSINESS_MODEL.md` 참고

---

## 🏗️ 전체 아키텍처

```
[사용자 브라우저]
      ↓  HTTPS
[Vercel / Railway]  ← 배포 플랫폼
      ↓
[Rails 8.1 애플리케이션]
  ├─ 랜딩페이지 (Tailwind CSS)
  ├─ 인증 (Devise)
  ├─ 구독 관리 (Stripe)
  ├─ 문서 시스템 (Markdown Renderer)
  └─ API 엔드포인트 (RESTful)
      ↓
[SQLite3 → PostgreSQL]  ← 데이터베이스
      ↓
[외부 서비스]
  ├─ Stripe  (결제)
  ├─ S3      (파일 저장)
  └─ Sentry  (에러 모니터링)
```

---

## 🛠️ 기술 스택

| 분류 | 기술 | 버전 | 역할 |
|------|------|------|------|
| **언어** | Ruby | 3.3 | 서버 사이드 언어 |
| **프레임워크** | Ruby on Rails | 8.1 | 웹 프레임워크 |
| **데이터베이스** | SQLite3 → PostgreSQL | - | 개발 → 프로덕션 |
| **인증** | Devise | - | 회원가입/로그인 |
| **UI** | Tailwind CSS | - | 스타일링 |
| **결제** | Stripe | - | 구독 결제 처리 |
| **파일** | ActiveStorage + S3 | - | 파일 업로드/저장 |
| **배포** | Vercel / Railway | - | 서버 배포 |
| **모니터링** | Sentry | - | 에러 추적 |

---

## 📁 프로젝트 폴더 구조

Rails 프로젝트를 생성하면 다음과 같은 구조가 만들어집니다:

```
chatdox/
├── app/
│   ├── controllers/        # 요청 처리 (비즈니스 로직)
│   ├── models/             # 데이터베이스 모델
│   ├── views/              # HTML 템플릿 (ERB)
│   ├── helpers/            # 뷰 헬퍼 메서드
│   └── assets/             # CSS, JS, 이미지
├── config/
│   ├── routes.rb           # URL 라우팅 설정
│   └── database.yml        # 데이터베이스 설정
├── db/
│   ├── migrate/            # 데이터베이스 변경 이력
│   └── schema.rb           # 현재 DB 구조
├── Gemfile                 # 라이브러리 목록
└── README.md
```

> 💡 **처음에는 모든 폴더를 이해할 필요가 없습니다.**
> 챕터를 진행하면서 각 폴더의 역할을 자연스럽게 익히게 됩니다.

---

## 🔄 요청 흐름 이해 (MVC 패턴)

Rails는 **MVC(Model-View-Controller)** 패턴을 따릅니다.

```
사용자가 URL 접속
      ↓
1. Router     → 어떤 Controller로 보낼지 결정
2. Controller → 데이터 처리, Model 호출
3. Model      → 데이터베이스에서 데이터 가져오기
4. View       → HTML 생성 (Controller에서 받은 데이터 사용)
      ↓
사용자에게 HTML 응답
```

**예시:**
```
https://chatdox.com/docs/1 접속
  → Router: docs#show 로 연결
  → Controller: 문서 ID=1 데이터 조회
  → Model: DB에서 문서 가져오기
  → View: 문서 HTML 렌더링
  → 사용자 화면에 표시
```

---

## 📊 데이터 모델 (핵심 구조)

채독스를 운영하기 위한 핵심 데이터 구조입니다:

```
User (사용자)
  ├─ email
  ├─ password
  └─ subscription_status   # free / basic / premium

Subscription (구독)
  ├─ user_id
  ├─ plan                  # basic / premium
  ├─ status                # active / cancelled
  └─ stripe_subscription_id

Document (문서)
  ├─ title
  ├─ content               # 마크다운 본문
  ├─ order_number          # 챕터 순서
  └─ access_level          # free / paid
```

---

## 🗺️ 학습 로드맵

```
Phase 1: 기초 & 환경 (챕터 1~5)
  1. 전체 구조 이해  ← 지금 여기
  2. Rails 기초
  3. 개발 환경 세팅
  4. 랜딩페이지 구축
  5. 프로젝트 구조 설계

Phase 2: 핵심 기능 구현 (챕터 6~16)
  6.  Database & Migrations
  7.  Authentication (Devise)
  8.  Authorization & 권한 관리
  9.  Payment (Stripe)
  10. 사용자 대시보드
  11. 관리자 대시보드
  12. Email & 알림
  13. 파일 업로드 (Active Storage)
  14. API 설계 & JSON
  15. 테스트 (RSpec)
  16. 성능 최적화 & 캐싱

Phase 3: 프로덕션 운영 (챕터 17~20)
  17. 보안 & OWASP
  18. 배포 (Railway / Render)
  19. 모니터링 & 에러 추적
  20. 런칭 & 운영
```

---

## ✅ 챕터 1 체크리스트

이 챕터를 마치기 전에 확인하세요:

- [ ] 채독스가 어떤 서비스인지 설명할 수 있다
- [ ] 전체 기술 스택 (Rails, Ruby, Tailwind 등)을 알고 있다
- [ ] MVC 패턴의 흐름을 이해했다
- [ ] 앞으로 20개 챕터에서 무엇을 만들지 그림이 그려진다

---

## ➡️ 다음 챕터

**[2. Ruby on Rails 8.1 기초 →](02_rails_basics.md)**

> Rails가 처음이라면? 걱정 마세요.
> 다음 챕터에서 핵심 개념만 빠르게 정리합니다.
