# 18. 배포 (Railway / Render)

> 로컬에서 완성한 Chatdox 플랫폼을 인터넷에 공개합니다.
> Railway를 사용해 Rails 앱을 배포하고,
> 환경 변수와 데이터베이스를 프로덕션 환경에 맞게 설정합니다.

---

## 📋 목표

1. **Railway** 배포 환경 이해
2. **환경 변수** 설정
3. **PostgreSQL** 프로덕션 DB 연결
4. **배포 & 검증**

---

## 1️⃣ 왜 Railway인가?

| 서비스 | 특징 | 무료 플랜 |
|--------|------|----------|
| **Railway** | Rails 최적화, 자동 감지, 간단 설정 | 월 $5 크레딧 |
| Render | 무료 플랜 있음, 슬립 모드 문제 | 무료 (슬립) |
| Fly.io | 컨테이너 기반, 학습 곡선 | 무료 |
| Heroku | 유명하지만 유료화됨 | 없음 |

**→ Chatdox는 Railway 사용** (Rails 자동 감지, PostgreSQL 통합 간편)

---

## 2️⃣ 배포 전 준비

### 로컬 확인

```bash
# 현재 상태 확인
rails s  # localhost:3000 정상 동작 확인

# Git 상태 깨끗한지 확인
git status  # nothing to commit
```

### Gemfile 확인

```ruby
# Gemfile

# 프로덕션 DB는 PostgreSQL
gem "pg", "~> 1.1"  # 없으면 추가

# 프로덕션 자산 압축
gem "bootsnap", require: false
```

```bash
bundle install
```

### database.yml 확인

```yaml
# config/database.yml

default: &default
  adapter: sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: db/development.sqlite3

# 프로덕션은 환경 변수 DATABASE_URL 사용
production:
  adapter: postgresql
  url: <%= ENV["DATABASE_URL"] %>
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
```

### Procfile 생성

```bash
# 프로젝트 루트에 Procfile 생성
echo "web: bundle exec puma -C config/puma.rb" > Procfile
```

---

## 3️⃣ Railway 배포

### 1단계: Railway 가입 & 프로젝트 생성

```
1. railway.app 접속
2. GitHub 계정으로 로그인
3. "New Project" 클릭
4. "Deploy from GitHub repo" 선택
5. chatdox-platform 저장소 선택
```

### 2단계: PostgreSQL 추가

```
Railway 대시보드에서:
1. "+ New" 클릭
2. "Database" → "Add PostgreSQL" 선택
3. 자동으로 DATABASE_URL 환경 변수 설정됨
```

### 3단계: 환경 변수 설정

Railway 대시보드 → Variables 탭:

```
SECRET_KEY_BASE = (자동 생성 또는 직접 입력)
RAILS_ENV       = production
RAILS_MASTER_KEY = (config/master.key 내용)
```

```bash
# SECRET_KEY_BASE 생성 (로컬에서)
rails secret
# → 긴 문자열 복사해서 Railway에 붙여넣기

# RAILS_MASTER_KEY 확인
cat config/master.key
```

### 4단계: 배포 확인

```
Railway가 자동으로:
1. GitHub push 감지
2. bundle install 실행
3. assets:precompile 실행
4. rails db:migrate 실행
5. Puma 서버 시작
```

---

## 4️⃣ 배포 후 작업

### DB Migration 실행

```bash
# Railway CLI 설치 (선택)
npm install -g @railway/cli
railway login
railway run rails db:migrate
```

또는 Railway 대시보드 → "Run Command":
```
rails db:migrate
```

### 도메인 설정

```
Railway 대시보드:
1. Settings → Domains
2. "Generate Domain" → 자동 도메인 생성
   예: chatdox-platform.up.railway.app
3. (선택) 커스텀 도메인 연결
```

---

## 5️⃣ 배포 체크리스트

### 배포 전
- [ ] `git status` clean 확인
- [ ] `rails s` 로컬 정상 동작 확인
- [ ] `Gemfile`에 `pg` gem 추가
- [ ] `config/database.yml` 프로덕션 설정 확인
- [ ] `Procfile` 생성
- [ ] GitHub에 최신 코드 push

### Railway 설정
- [ ] Railway 프로젝트 생성
- [ ] GitHub 저장소 연결
- [ ] PostgreSQL 추가
- [ ] 환경 변수 설정 (SECRET_KEY_BASE, RAILS_MASTER_KEY)
- [ ] 첫 배포 완료 확인

### 배포 후 검증
- [ ] 사이트 접속 (생성된 도메인)
- [ ] `/docs` 페이지 동작 확인
- [ ] 에러 로그 확인 (Railway 대시보드 → Logs)

---

## 6️⃣ 자주 발생하는 에러

### Assets precompile 실패

```bash
# config/environments/production.rb 확인
config.assets.compile = true  # 임시 해결 (개발 단계)
```

### master.key 없음 에러

```
ActionDispatch::Http::MissingKeyError
```

```
해결: RAILS_MASTER_KEY 환경 변수에 config/master.key 내용 입력
(config/master.key는 .gitignore에 포함되어 있어 GitHub에 없음)
```

### Database migration 안 됨

```bash
# Railway 콘솔에서 직접 실행
railway run rails db:migrate RAILS_ENV=production
```

---

## 7️⃣ 배포 후 운영

### 코드 업데이트 배포

```bash
# 로컬에서 개발 후
git add .
git commit -m "feat: ..."
git push origin main
# → Railway 자동 감지 & 재배포 (약 2~3분)
```

### 로그 모니터링

```
Railway 대시보드 → Deployments → Logs
실시간 로그 확인 가능
```

---

## 🎯 핵심 원칙

| 원칙 | 설명 |
|------|------|
| **환경 변수로 비밀 관리** | SECRET_KEY_BASE, DB URL은 코드에 절대 포함 금지 |
| **master.key는 Git 제외** | .gitignore에 포함 (기본값), Railway 환경 변수로 전달 |
| **DB는 PostgreSQL** | 프로덕션에서 SQLite 사용 금지 |
| **Git push = 배포** | Railway가 자동으로 처리 |

---

## 📚 다음 단계

✅ 배포 완료!

다음에는:
- **19장: 모니터링 & 에러 추적** - Sentry, 로그 관리
- **20장: 런칭 & 운영** - 도메인, SEO, 분석
