# 🛠️ SETUP 가이드

채독스 프로젝트의 개발 환경 설정, 배포, 그리고 운영 프로세스를 문서화합니다.

**대상 독자:** 개발 팀, DevOps 팀, 새로운 팀원

---

## 📋 목차

### 저장소 관리

| # | 제목 | 설명 | 소요 시간 |
|---|------|------|---------|
| [01](01_github_repo_setup.md) | GitHub 저장소 생성 및 푸시 | `chatdox-curriculum` 생성 | ~5분 |
| 02 | (예정) Subtree 통합 | `chatdox-platform`에 curriculum 연결 | ~10분 |
| 03 | (예정) 협력자 권한 설정 | 팀원 초대 및 권한 관리 | ~5분 |

### 배포 & 운영 (추후)

| # | 제목 | 설명 |
|---|------|------|
| 04 | (예정) CI/CD 파이프라인 | GitHub Actions 설정 |
| 05 | (예정) 환경 변수 관리 | .env 파일 관리 |
| 06 | (예정) 배포 체크리스트 | 프로덕션 배포 전 확인사항 |

---

## 🎯 빠른 시작

### 처음 프로젝트를 시작하는 경우

1. **[01. GitHub 저장소 생성 및 푸시](01_github_repo_setup.md)** 
   ```bash
   # 로컬 코드를 GitHub에 푸시
   ```

2. **[02. Subtree 통합](02_subtree_integration.md)** (예정)
   ```bash
   # chatdox-platform에 curriculum 연결
   ```

3. **[03. 협력자 권한 설정](03_team_collaboration.md)** (예정)
   ```bash
   # 팀원 초대 및 권한 부여
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

- [x] 로컬 프로젝트 구조 완성 (docs/, prompts/, QA/)
- [ ] GitHub `chatdox-curriculum` 리포 생성
- [ ] 로컬 코드 푸시
- [ ] `chatdox-platform` 리포 생성
- [ ] Subtree 통합
- [ ] CI/CD 파이프라인 설정

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
