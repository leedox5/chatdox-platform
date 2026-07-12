# SETUP 01: GitHub 저장소 생성 및 푸시

**목적:** `chatdox-curriculum` 리포지토리를 GitHub에 생성하고 로컬 프로젝트를 푸시합니다.

**소요 시간:** ~5분

---

## 📋 사전 준비

- ✅ Git 설치 완료
- ✅ GitHub 계정 생성
- ✅ GitHub SSH 키 설정 완료 ([참고: 03_dev_setup.md](../docs/03_dev_setup.md))
- ✅ 현재 폴더 구조:
  ```
  d:\dev\saas\
  ├─ docs/
  ├─ prompts/
  ├─ QA/
  └─ README.md
  ```

---

## 🚀 Step 1: GitHub에서 리포지토리 생성

### 1-1. GitHub 로그인
[https://github.com](https://github.com) 에서 로그인

### 1-2. 새 리포지토리 생성
1. 우측 상단 `+` 아이콘 → **New repository**
2. 다음과 같이 입력:

| 항목 | 값 |
|------|-----|
| Repository name | `chatdox-curriculum` |
| Description | `Chatdox - 20개 챕터 완전 문서 + 학습 자료` |
| Visibility | **Private** ⭐ (비공개) |
| Add .gitignore | Python (또는 불필요) |
| Add a license | 선택 사항 |

3. **Create repository** 클릭

### 1-3. 생성 완료
GitHub 페이지에서 다음이 보입니다:
```
Quick setup — if you've done this kind of thing before
or	    HTTPS SSH
```

🔑 **SSH 선택** (이미 SSH 키 설정했다면)

---

## 🖥️ Step 2: 로컬 폴더에서 Git 설정

### 2-1. 터미널 열기
```bash
# 프로젝트 폴더로 이동
cd d:\dev\saas
```

### 2-2. 현재 상태 확인

```bash
# .git 폴더 확인
ls -la | grep git

# 또는
Get-Item .git -Force
```

**Case A: `.git` 폴더가 없는 경우**
```bash
git init
```

**Case B: `.git` 폴더가 이미 있는 경우**
```bash
git status
# → 이미 Git으로 초기화된 상태
```

### 2-3. 모든 파일 추가

```bash
git add .
```

**확인:**
```bash
git status
# Changes to be committed: ... 표시됨
```

### 2-4. 첫 커밋

```bash
git commit -m "Initial: docs, prompts, QA, and project structure"
```

출력 예시:
```
[main (root-commit) abc1234]
 6 files changed, 500 insertions(+)
 create mode 100644 README.md
 create mode 100644 docs/01_overview.md
 ...
```

### 2-5. 기본 브랜치 이름 변경

```bash
git branch -M main
```

> 💡 GitHub의 기본 브랜치가 `main`이므로, 로컬도 맞춰줍니다.

### 2-6. 원격 저장소 연결

GitHub 페이지에서 SSH 주소 복사 (또는 다음 형식 사용):

```bash
git remote add origin git@github.com:[USERNAME]/chatdox-curriculum.git
```

**예시:**
```bash
git remote add origin git@github.com:john-doe/chatdox-curriculum.git
```

확인:
```bash
git remote -v
# origin  git@github.com:[USERNAME]/chatdox-curriculum.git (fetch)
# origin  git@github.com:[USERNAME]/chatdox-curriculum.git (push)
```

### 2-7. 푸시

```bash
git push -u origin main
```

🎉 **출력 예시:**
```
Enumerating objects: 6, done.
Counting objects: 100% (6/6), done.
Delta compression using up to 8 threads
Compressing objects: 100% (4/4), done.
Writing objects: 100% (6/6), 2.50 KiB | 2.50 MiB/s
...
* [new branch]      main -> main
Branch 'main' set up to track remote branch 'main' from 'origin'.
```

---

## ✅ Step 3: 검증

### 3-1. GitHub에서 확인
1. [https://github.com/[username]/chatdox-curriculum](https://github.com) 접속
2. 파일들이 보이는지 확인:
   ```
   ✅ docs/ (4개 챕터 문서)
   ✅ prompts/ (UI/UX 설계)
   ✅ QA/ (의사결정 기록)
   ✅ SETUP/ (이 가이드)
   ✅ README.md
   ```

### 3-2. Private 확인
- 리포 설정: Settings → **Visibility**
- **Private** 표시 확인 ⭐

### 3-3. 로컬에서 확인

```bash
git log --oneline
# abc1234 Initial: docs, prompts, QA, and project structure

git remote -v
# origin  git@github.com:[USERNAME]/chatdox-curriculum.git (fetch)
# origin  git@github.com:[USERNAME]/chatdox-curriculum.git (push)
```

---

## 📝 향후 작업 (Git Subtree 준비)

이제 `chatdox-platform` (Rails 앱)에서 이 리포를 Subtree로 추가할 준비가 됐습니다.

```bash
# chatdox-platform 폴더에서 실행 (추후)
git subtree add --prefix docs/curriculum \
  git@github.com:[USERNAME]/chatdox-curriculum.git main
```

---

## 🐛 문제 해결

### SSH 연결 오류
```bash
Permission denied (publickey).
```

**해결:**
```bash
# SSH 키 확인
ssh -T git@github.com

# 또는 HTTPS 사용 (대신 토큰 필요)
git remote set-url origin https://github.com/[USERNAME]/chatdox-curriculum.git
```

### 파일이 보이지 않음
```bash
git status
# 추가하지 않은 파일 확인

git add [filename]
git commit -m "Add missing files"
git push
```

### 브랜치 이름 오류
```bash
# 현재 브랜치 확인
git branch

# GitHub와 다르면
git branch -M main
git push -u origin main
```

---

## ✨ 다음 단계

- [ ] **chatdox-platform** (Rails 앱) 프로젝트 생성
- [ ] `chatdox-platform`에 `chatdox-curriculum`을 Git Subtree로 통합
- [ ] Rails에서 문서 접근 로직 구현

---

## 📚 Related

- [QA/01_github_strategy.md](../QA/01_github_strategy.md) — GitHub 전략 배경
- [docs/03_dev_setup.md](../docs/03_dev_setup.md) — Git/SSH 설정

---

**완료 후:** `chatdox-curriculum` 리포가 GitHub에 비공개로 생성되어 있어야 합니다. ✅
