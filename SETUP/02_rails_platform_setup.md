---
title: "Rails 플랫폼 생성 및 초기 실행"
order: 2
status: "완료"
tech: "Rails 8.1.3, Ruby 3.4.9, Tailwind CSS, Git Subtree"
dependency: "01_github_repo_setup.md"
---

# SETUP 02: Rails 플랫폼 생성 및 초기 실행

**목적:** `chatdox-platform` Rails 애플리케이션을 생성하고, `chatdox-curriculum`을 Git Subtree로 통합한 후, 개발 서버를 실행합니다.

**소요 시간:** ~15분

---

## 📋 사전 준비

- ✅ Rails 설치 완료 ([docs/03_dev_setup.md](../docs/03_dev_setup.md) 참고)
- ✅ chatdox-curriculum GitHub에 푸시 완료
- ✅ chatdox-platform GitHub 리포 생성 (Public, MIT License)
- ✅ Git 설정 완료 (HTTPS 또는 SSH)

---

## 🚀 Step 1: Rails 앱 생성

### 1-1. 개발 디렉토리로 이동

```bash
cd d:\dev
```

### 1-2. Rails 앱 생성

```bash
rails new chatdox-platform --css tailwind --database sqlite3 --skip-test
```

**옵션 설명:**
- `--css tailwind`: Tailwind CSS 통합
- `--database sqlite3`: SQLite3 (개발 단계에서 간단)
- `--skip-test`: 테스트 도구 건너뛰기 (나중에 추가)

**생성 예시:**
```
create  chatdox-platform/Gemfile
create  chatdox-platform/Rakefile
...
Bundle complete! ...
```

### 1-3. 프로젝트 폴더로 이동

```bash
cd chatdox-platform
```

---

## 🚀 Step 2: Git 초기화 및 커밋

### 2-1. Git 저장소 초기화

```bash
git init
```

### 2-2. 모든 파일 추가

```bash
git add .
```

### 2-3. 첫 커밋

```bash
git commit -m "Initial Rails 8.1.3 app with Tailwind CSS"
```

**출력 예시:**
```
[main (root-commit) abc1234] Initial Rails 8.1.3 app with Tailwind CSS
 100 files changed, 5000 insertions(+)
 ...
```

### 2-4. 기본 브랜치 설정

```bash
git branch -M main
```

---

## 🚀 Step 3: GitHub 원격 연결

### 3-1. 원격 저장소 추가 (HTTPS)

```bash
git remote add origin https://github.com/[USERNAME]/chatdox-platform.git
```

**확인:**
```bash
git remote -v

# 출력:
# origin  https://github.com/[USERNAME]/chatdox-platform.git (fetch)
# origin  https://github.com/[USERNAME]/chatdox-platform.git (push)
```

### 3-2. GitHub에 푸시

```bash
git push -u origin main
```

**토큰 입력:**
- GitHub 계정이 없다면 로그인 메시지 표시
- Personal Access Token 입력 (Settings → Developer settings)

**성공 메시지:**
```
Enumerating objects: 100, done.
...
* [new branch]      main -> main
Branch 'main' set up to track remote branch 'main' from 'origin'.
```

---

## 🚀 Step 4: Git Subtree로 Curriculum 통합

### 4-1. Subtree 추가 (HTTPS)

```bash
git subtree add --prefix docs/curriculum \
  https://github.com/[USERNAME]/chatdox-curriculum.git main
```

**토큰 입력:**
- 개인 Private 리포이므로 다시 토큰 필요

**성공 메시지:**
```
Added 'docs/curriculum' as 'subtree' with squash option
```

### 4-2. 폴더 확인

```bash
ls docs/curriculum/

# 출력:
# docs/
# prompts/
# QA/
# SETUP/
# TIPS/
# README.md
```

✅ curriculum이 `docs/curriculum/` 경로에 있는지 확인

### 4-3. 문서 접근 테스트

```bash
cat docs/curriculum/README.md | head -20
```

첫 20줄이 보이면 성공! ✅

---

## 🚀 Step 5: Rails 개발 서버 실행

### 5-1. 서버 시작

```bash
bin/rails server
# 또는 단축
bin/rails s
```

**출력 예시:**
```
=> Booting Puma
=> Rails 8.1.3 application starting in development
=> Run `rails server --help` for more startup options
Puma starting in single mode...
* Puma version: 6.x.x (ruby 3.4.9)
* Min threads: 5
* Max threads: 5
* Environment: development
* PID: 12345
* Listening on http://127.0.0.1:3000
* Use Ctrl-C to stop
```

### 5-2. 브라우저에서 접근

- **URL:** http://localhost:3000
- **예상 화면:** Rails 시작 페이지 (Congratulations 🎉)

---

## ✅ Step 6: 검증

### 6-1. Rails 버전 확인

```bash
bin/rails --version
# Rails 8.1.3
```

### 6-2. Ruby 버전 확인

```bash
ruby --version
# ruby 3.4.9 ...
```

### 6-3. Git 상태 확인

```bash
git status
# On branch main
# nothing to commit, working tree clean
```

### 6-4. Curriculum 접근 확인

```bash
ls docs/curriculum/docs/
# 01_overview.md
# 02_rails_basics.md
# 03_dev_setup.md
# 04_landing_page.md
```

---

## 📋 최종 체크리스트

- [x] Rails 앱 생성 (`rails new ... --css tailwind`)
- [x] Git 초기화 및 첫 커밋
- [x] GitHub 원격 연결 및 푸시
- [x] Git Subtree로 curriculum 통합
- [x] `bin/rails s` 실행
- [x] http://localhost:3000 접근 성공
- [x] curriculum 폴더 확인

---

## 🎯 현재 폴더 구조

```
chatdox-platform/
├─ docs/
│  └─ curriculum/          ← Subtree로 연결
│     ├─ docs/             (20개 챕터)
│     ├─ prompts/          (UI/UX 설계)
│     ├─ QA/               (의사결정)
│     ├─ SETUP/            (개발 가이드)
│     ├─ TIPS/             (노하우)
│     └─ README.md
├─ app/
│  ├─ controllers/
│  ├─ models/
│  ├─ views/
│  └─ assets/
├─ config/
│  ├─ routes.rb
│  └─ database.yml
├─ bin/
│  ├─ rails
│  └─ server
├─ Gemfile
├─ README.md (Rails 자동 생성)
└─ .git/                   (Git Subtree 포함)
```

---

## 💡 팁

### 서버 종료
```bash
Ctrl + C
```

### 콘솔 로그 실시간 확인
```
Puma가 요청 로그를 자동으로 표시합니다
```

### 파일 수정 시 자동 리로드
```
Rails는 대부분의 파일을 자동으로 감지해서 리로드합니다
(필요시 브라우저 새로고침)
```

### Subtree 업데이트 (나중에)
```bash
git subtree pull --prefix docs/curriculum \
  https://github.com/[USERNAME]/chatdox-curriculum.git main --squash
```

---

## 🤔 자주 묻는 질문

**Q: "bin/rails: No such file or directory" 에러?**  
A: `rails new` 명령어가 제대로 실행되지 않았을 수 있습니다. 위의 Step 1을 다시 확인하세요.

**Q: Subtree 추가 중 "permission denied" 에러?**  
A: GitHub 토큰이 만료되었을 수 있습니다. 새로운 토큰을 생성하세요.

**Q: localhost:3000이 이미 사용 중이라는 오류?**  
A: 다른 포트 사용:
```bash
bin/rails server -p 3001
```

**Q: curriculum 폴더가 `docs/` 아래에 없고 root에 있다?**  
A: Subtree 경로를 확인하세요:
```bash
git subtree add --prefix docs/curriculum ...
```
(--prefix 확인 필수)

**Q: docs/curriculum이 비어있다?**  
A: Subtree 풀링 실패. 다시 시도:
```bash
git subtree add --prefix docs/curriculum \
  https://github.com/[USERNAME]/chatdox-curriculum.git main --squash
```

---

## 🔗 다음 단계

이제 준비 완료! 다음 가능한 작업:

1. **Landing Page 구현** ([docs/04_landing_page.md](../docs/curriculum/docs/04_landing_page.md))
   ```bash
   bin/rails generate controller pages home
   ```

2. **라우팅 추가** (config/routes.rb)
   ```ruby
   root "pages#home"
   ```

3. **Devise 인증 추가** (06_authentication.md - 예정)

---

## 📚 관련 문서

- [SETUP/01_github_repo_setup.md](01_github_repo_setup.md) — GitHub 리포 생성
- [docs/03_dev_setup.md](../docs/curriculum/docs/03_dev_setup.md) — 개발 환경 설정
- [docs/04_landing_page.md](../docs/curriculum/docs/04_landing_page.md) — 랜딩 페이지 구현
- [QA/01_github_strategy.md](../QA/01_github_strategy.md) — 2-Repository 분리 전략

---

**마지막 업데이트:** 2026-07-09

**상태:** 실무 테스트 완료 ✅
