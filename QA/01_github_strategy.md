# Q&A 01: GitHub 저장소 전략

**날짜:** 2026-07-09  
**카테고리:** 프로젝트 아키텍처, 버전 관리

---

## ❓ 질문

우리는 *.md 파일(상품 콘텐츠)을 생성하고 있는데, 이는 상품의 핵심이고 소스 코드와는 구별되어야 할 거 같습니다. GitHub를 이용해 이를 위한 전략을 세울 수 있을까요?

---

## ✅ 답변

### 핵심 전략: 2-Repository 분리

상품 콘텐츠(문서)와 실제 구현 코드를 분리하는 것이 베스트 프랙티스입니다.

```
Organization: Chatdox
├─ chatdox-platform (공개)
│   └─ 실제 사용자가 사용하는 Rails 애플리케이션
├─ chatdox-curriculum (비공개) ⭐
│   └─ 상품 핵심: 20개 챕터 문서 + 자산
└─ chatdox-templates (공개, 선택사항)
    └─ 각 챕터별 완성 코드 스냅샷 (학습용)
```

---

### 각 리포지토리의 역할

| 리포지토리 | 공개 여부 | 내용 | 액세스 | 목적 |
|-----------|---------|------|--------|------|
| **chatdox-platform** | ✅ 공개 | Rails 애플리케이션 | 모두 | 실제 서비스 제공 |
| **chatdox-curriculum** | ❌ 비공개 | 20개 md 문서 (상품) | 구독자만 | 상품 보호 & 수익화 |
| **chatdox-templates** | ✅ 공개 | 챕터별 완성 코드 | 모두 | 신뢰도 + 학습 자료 |

---

### 현실적 마이그레이션 계획

#### Phase 1: 로컬 폴더 구조 정리 (현재)
```
d:\dev\saas\
├─ docs/          ← 상품 문서들 (현재 위치)
├─ prompts/       ← 내부 설계 문서
└─ README.md
```

#### Phase 2: 로컬에서 폴더 분리
```
d:\dev\
├─ chatdox-curriculum/
│   ├─ docs/                # 20개 챕터 문서
│   ├─ assets/              # 이미지, 다이어그램
│   ├─ prompts/             # 내부 설계 (비공개)
│   └─ README.md            # 목차 & 상품 설명
│
├─ chatdox-platform/        # 실제 Rails 앱 (아직 미생성)
│   ├─ app/
│   ├─ config/
│   ├─ db/
│   ├─ Gemfile
│   └─ README.md
│
└─ chatdox-templates/       # (나중에)
```

#### Phase 3: GitHub에 푸시
```
GitHub:
├─ github.com/[username]/chatdox-curriculum    (비공개)
├─ github.com/[username]/chatdox-platform     (공개)
└─ github.com/[username]/chatdox-templates    (공개)
```

---

### 비공개 리포지토리 액세스 관리

구독자에게 문서 접근 권한을 부여하는 방법:

**Option 1: GitHub 협력자 초대 (간단)**
```
GitHub Settings → Collaborators
→ 구독자 GitHub 계정 초대
→ Read-only 권한 부여
```

**Option 2: Deploy Key (자동화)**
```bash
# 비공개 리포에 Deploy Key 설정
# Rails 앱에서 자동으로 문서 풀링 가능
# (구독 검증 후 동적으로 제공)
```

**Option 3: Private Package (고급)**
```
GitHub Packages를 이용해 문서를 패키지로 배포
구독자만 설치/액세스 가능
```

---

### 장점 정리

✅ **상품 보호**  
   - 문서는 비공개로 엄격하게 관리
   - 구독자만 액세스 가능
   - 불법 복제 방지

✅ **코드 공개 신뢰도**  
   - Rails 구현 코드는 공개
   - 투명성 & 신뢰도 향상
   - 오픈소스 커뮤니티 피드백

✅ **학습 자료 풍부**  
   - templates 리포로 각 단계별 완성 코드 제공
   - 사용자가 쉽게 따라할 수 있음

✅ **독립적 관리**  
   - 문서 업데이트와 코드 배포 독립적으로 가능
   - 버전 관리 유연성

✅ **추후 확장성**  
   - 다른 언어/프레임워크 추가 시 쉬움
   - 팀 협업 확대 용이

---

### 예상 비용 (GitHub)

- **비공개 리포지토리**: ✅ 무제한 무료
- **협력자 초대**: ✅ 무제한 무료
- **GitHub Packages**: 💰 월 $5+ (선택사항)

---

## ⚠️ 추가 질문: Cross-Repository 액세스 문제

> **Q**: 두 리포지토리가 분리되면, `chatdox-platform` (Rails 앱)에서  
> `chatdox-curriculum` (문서)의 콘텐츠에 어떻게 접근하지?

### 해결책 비교

| 방법 | 난이도 | 보안 | 유지보수 | 추천 |
|------|--------|------|---------|------|
| **Git Submodule** | 🟡 중간 | ✅ 높음 | 🟡 중간 | ✅ 추천 |
| **Git Subtree** | 🟡 중간 | ✅ 높음 | 🟡 중간 | ⭐ |
| **HTTP API** | 🟢 쉬움 | 🟡 중간 | ✅ 높음 | ✅ 추천 |
| **Ruby Gem** | 🔴 어려움 | ✅ 높음 | 🟡 중간 | (고급) |
| **빌드 시 다운로드** | 🟢 쉬움 | ⚠️ 낮음 | ✅ 높음 | |
| **단일 비공개 repo** | 🟢 쉬움 | ✅ 높음 | ⚠️ 낮음 | |

---

### 추천 방안 3가지

#### 🥇 1순위: HTTP API (가장 실용적)

```ruby
# app/controllers/docs_controller.rb
class DocsController < ApplicationController
  def show
    @doc = fetch_from_curriculum_api(params[:id])
  end

  private

  def fetch_from_curriculum_api(doc_id)
    # 구독자 인증 후, API 호출로 문서 조회
    response = Faraday.get(
      "https://docs.chatdox.com/api/v1/documents/#{doc_id}",
      headers: { "Authorization" => "Bearer #{current_user.api_token}" }
    )
    JSON.parse(response.body)
  end
end
```

**장점:**
- ✅ 가장 유연한 구조
- ✅ 구독 검증 로직 추가 용이
- ✅ 두 앱이 완전히 독립적
- ✅ 문서 서버를 별도로 확장 가능

**단점:**
- ⚠️ 네트워크 지연 가능성
- ⚠️ API 서버 추가 관리 필요

---

#### 🥈 2순위: Git Subtree (단순함)

```bash
# chatdox-platform 리포에서
git subtree add --prefix docs/curriculum \
  https://github.com/[username]/chatdox-curriculum.git main

# 업데이트할 때
git subtree pull --prefix docs/curriculum \
  https://github.com/[username]/chatdox-curriculum.git main
```

**구조:**
```
chatdox-platform/
├─ app/
├─ config/
└─ docs/
   └─ curriculum/        # chatdox-curriculum의 복사본
       ├─ docs/          # ← 이 파일들이 Rails에서 접근 가능
       └─ assets/
```

**장점:**
- ✅ Rails에서 파일 직접 접근 가능
- ✅ 설정이 간단
- ✅ 배포 시 자동으로 포함됨

**단점:**
- ⚠️ Git 히스토리가 꼬일 수 있음
- ⚠️ 문서 수정 후 push가 복잡함

---

#### 🥉 3순위: Git Submodule (전통적)

```bash
# chatdox-platform 리포에서
git submodule add \
  https://github.com/[username]/chatdox-curriculum.git docs/curriculum

# 배포 시
git submodule update --recursive --remote
```

**장점:**
- ✅ 명확한 버전 관리
- ✅ 두 리포의 커밋 연결 추적 가능

**단점:**
- ⚠️ 팀원들의 학습 곡선이 높음
- ⚠️ CI/CD 설정이 복잡함

---

### 🎯 **최종 추천: HTTP API 방식**

**이유:**

1. **보안**: 구독 검증을 Rails 앱에서 완전히 제어
2. **확장성**: 나중에 모바일 앱, 다른 클라이언트에도 확대 가능
3. **배포 독립성**: Rails 앱 배포와 문서 업데이트가 완전히 분리
4. **실시간 업데이트**: 문서 변경 시 즉시 반영

**구현 로드맵:**

```
Phase 1 (현재): Git Subtree로 임시 구성
  ↓
Phase 2: 간단한 문서 서버 구축 (GitHub Pages 또는 간단한 Rails)
  ↓
Phase 3: Chatdox Platform에 API 클라이언트 통합
  ↓
Phase 4: 모바일/별도 클라이언트 확대
```

---

## 🎯 최종 결론

### 지금 바로 (개발 단계)
→ **Git Subtree** 사용 (단순함)

### 상품화 이후 (서비스 중)
→ **HTTP API** 방식으로 마이그레이션 (안정성, 확장성)

### 코드 예시 (API 방식)

```ruby
# Gemfile
gem "faraday"

# app/services/curriculum_service.rb
class CurriculumService
  def initialize(user)
    @user = user
  end

  def get_document(doc_id)
    response = faraday_client.get("/api/v1/documents/#{doc_id}")
    JSON.parse(response.body) if response.success?
  rescue => e
    Rails.logger.error("Curriculum API Error: #{e.message}")
    nil
  end

  private

  def faraday_client
    Faraday.new(
      url: Rails.env.production? ? "https://curriculum.chatdox.com" : "http://localhost:3001",
      headers: {
        "Authorization" => "Bearer #{@user.api_token}",
        "Content-Type" => "application/json"
      }
    )
  end
end
```

---

## 📝 다음 단계

- [ ] 로컬에서 폴더 구조 정리
- [ ] GitHub 계정에서 3개 리포지토리 생성
- [ ] 콘텐츠 마이그레이션
- [ ] 협력자 권한 설정
- [ ] **Git Subtree로 임시 통합** ← NEW
- [ ] **추후 API 마이그레이션 계획** ← NEW

---

**Related:**
- [README.md](../README.md)
- [docs/01_overview.md](../docs/01_overview.md)
- QA 02 (예정): "API 서버 아키텍처"
