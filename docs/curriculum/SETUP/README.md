# 🛠️ SETUP 가이드

채독스 프로젝트의 개발 환경 설정, 배포, 그리고 운영 프로세스를 문서화합니다.

**대상 독자:** 개발 팀, DevOps 팀, 새로운 팀원

---

## 📋 목차

### 저장소 관리

| # | 제목 | 설명 | 소요 시간 | 상태 |
|---|------|------|---------|------|
| [01](01_github_repo_setup.md) | GitHub 저장소 생성 및 푸시 | `chatdox-curriculum` 생성 | ~5분 | ✅ |
| [02](02_rails_platform_setup.md) | Rails 플랫폼 생성 및 초기 실행 | `chatdox-platform` 생성 + Subtree 통합 | ~15분 | ✅ |
| 03 | (예정) Git Subtree 관리 | Subtree 업데이트 및 트러블슈팅 | ~10분 | - |
| 04 | (예정) 협력자 권한 설정 | 팀원 초대 및 권한 관리 | ~5분 | - |

### 배포 & 운영 (추후)

| # | 제목 | 설명 |
|---|------|------|
| 05 | (예정) CI/CD 파이프라인 | GitHub Actions 설정 |
| 06 | (예정) 환경 변수 관리 | .env 파일 관리 |
| 07 | (예정) 배포 체크리스트 | 프로덕션 배포 전 확인사항 |

---

## 🎯 빠른 시작

### 처음 프로젝트를 시작하는 경우

1. **[01. GitHub 저장소 생성 및 푸시](01_github_repo_setup.md)** 
   ```bash
   # 로컬 코드를 GitHub에 푸시
   ```

2. **[02. Rails 플랫폼 생성 및 초기 실행](02_rails_platform_setup.md)** ✅
   ```bash
   # Rails 앱 생성 + Subtree 통합 + 서버 실행
   ```

3. **[03. Git Subtree 관리](03_git_subtree_management.md)** (예정)
   ```bash
   # Subtree 업데이트 및 트러블슈팅
   ```

### 기존 프로젝트에 참여하는 경우

```bash
# 1. 리포 클론
git clone git@github.com:[USERNAME]/chatdox-curriculum.git

# 2. Subtree로 platform에 통합 (플랫폼 리포에서)
git subtree add --prefix docs/curriculum [curriculum-url] main

# 3. 끝!
```

---

## 📂 폴더 구조

```
chatdox-curriculum/
├─ docs/          → 20개 챕터 문서 (상품)
├─ prompts/       → UI/UX 설계 (내부)
├─ QA/            → 의사결정 기록
├─ SETUP/         → 이 가이드들 ← 현재 위치
└─ README.md      → 프로젝트 개요
```

---

## 🔗 관련 문서

**프로젝트 전략:**
- [QA/01_github_strategy.md](../QA/01_github_strategy.md) — GitHub 2-Repository 분리 전략

**학습 자료:**
- [docs/03_dev_setup.md](../docs/03_dev_setup.md) — Git 및 SSH 설정 방법

---

## ✅ 체크리스트

현재 프로젝트 상태:

- [x] 로컬 프로젝트 구조 완성 (docs/, prompts/, QA/, SETUP/, TIPS/)
- [x] GitHub `chatdox-curriculum` 리포 생성
- [x] 로컬 코드 푸시
- [x] GitHub `chatdox-platform` 리포 생성
- [x] Rails 8.1.3 앱 생성
- [x] Subtree 통합 (curriculum 연결)
- [x] 개발 서버 실행 (localhost:3000 ✅)
- [ ] 랜딩 페이지 구현
- [ ] 인증 (Devise) 추가
- [ ] CI/CD 파이프라인 설정
- [ ] 프로덕션 배포

---

## 💡 팁

**Git 명령어 자주 사용?**
```bash
git status     # 현재 상태
git log --oneline  # 커밋 히스토리
git remote -v  # 원격 저장소 확인
```

**SSH 연결 문제?**
```bash
ssh -T git@github.com  # SSH 키 테스트
```

---

**마지막 업데이트:** 2026-07-09
