# 3. 개발 환경 세팅

> 이 챕터에서는 채독스 개발을 시작하기 위한 환경을 컴퓨터에 구축합니다.
> 설치 순서를 그대로 따라하면 동일한 환경이 만들어집니다.

---

## 📋 설치 목록 (한눈에 보기)

| 순서 | 도구 | 버전 | 용도 |
|------|------|------|------|
| 1 | Git | 최신 | 버전 관리 |
| 2 | rbenv | 최신 | Ruby 버전 관리 |
| 3 | Ruby | 3.3.x | 프로그래밍 언어 |
| 4 | Rails | 8.1.x | 웹 프레임워크 |
| 5 | Node.js | LTS | Tailwind CSS 빌드 |
| 6 | VS Code | 최신 | 코드 편집기 |
| 7 | GitHub 계정 | - | 코드 저장소 |

---

## 1️⃣ Git 설치

### macOS

```bash
# Homebrew 설치 (없는 경우)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Git 설치
brew install git
```

### Windows

[https://git-scm.com/download/win](https://git-scm.com/download/win) 에서 다운로드 후 설치

### 설치 확인

```bash
git --version
# git version 2.x.x
```

### Git 초기 설정

```bash
git config --global user.name "이름"
git config --global user.email "이메일@example.com"
```

---

## 2️⃣ Ruby 설치 (rbenv 사용)

Ruby 버전을 유연하게 관리하기 위해 **rbenv**를 사용합니다.

### macOS

```bash
# rbenv 설치
brew install rbenv ruby-build

# rbenv 초기화 (쉘 설정 추가)
echo 'eval "$(rbenv init -)"' >> ~/.zshrc
source ~/.zshrc

# Ruby 3.3 설치
rbenv install 3.3.6
rbenv global 3.3.6

# 설치 확인
ruby --version
# ruby 3.3.6
```

### Windows

[RubyInstaller](https://rubyinstaller.org/downloads/) 에서 **Ruby+Devkit 3.3.x (x64)** 다운로드 후 설치

```bash
# 설치 확인
ruby --version
```

> 💡 설치 마지막 단계에서 **"Run 'ridk install'"** 체크박스를 반드시 체크하세요.

### Windows (WSL)

WSL(Windows Subsystem for Linux)을 쓰면 Windows에서도 macOS/Linux와 동일한 방식으로 rbenv를 사용할 수 있습니다. RubyInstaller 대신 이 방법을 쓰고 싶다면 아래를 따라하세요.

> 💡 WSL2 + Ubuntu가 이미 설치되어 있다는 전제입니다. 아직이라면 PowerShell(관리자 권한)에서 `wsl --install` 실행 후 재부팅하세요.

```bash
# 빌드에 필요한 패키지 설치
sudo apt update
sudo apt install -y build-essential libssl-dev libreadline-dev zlib1g-dev libffi-dev libyaml-dev

# rbenv + ruby-build 설치
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

# Ruby 3.3 설치
rbenv install 3.3.6
rbenv global 3.3.6

# 설치 확인
ruby --version
# ruby 3.3.6
```

> 💡 VS Code에서 WSL 안의 프로젝트를 열려면 [WSL 확장](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl)을 설치하고, WSL 터미널에서 `code .`를 실행하세요.

---

## 3️⃣ Rails 설치

```bash
# Rails 8.1 설치
gem install rails -v "~> 8.1"

# 설치 확인
rails --version
# Rails 8.1.x
```

---

## 4️⃣ Node.js 설치

Tailwind CSS 빌드에 필요합니다.

### macOS

```bash
brew install node
```

### Windows

[https://nodejs.org](https://nodejs.org) 에서 **LTS 버전** 다운로드 후 설치

### 설치 확인

```bash
node --version   # v20.x.x 이상
npm --version    # 10.x.x 이상
```

---

## 5️⃣ VS Code 설치 & 설정

[https://code.visualstudio.com](https://code.visualstudio.com) 에서 다운로드

### 권장 확장 프로그램

VS Code에서 `Ctrl+Shift+X` (Extensions) 열고 설치:

| 확장 이름 | 용도 |
|-----------|------|
| Ruby LSP | Ruby 코드 자동완성, 오류 표시 |
| ERB Formatter/Beautify | ERB 파일 포맷팅 |
| Tailwind CSS IntelliSense | Tailwind 클래스 자동완성 |
| GitLens | Git 이력 시각화 |
| GitHub Copilot | AI 코드 어시스턴트 |

---

## 6️⃣ GitHub 계정 & SSH 설정

### GitHub 계정 생성

[https://github.com](https://github.com) 에서 계정 생성

### SSH 키 생성

```bash
ssh-keygen -t ed25519 -C "이메일@example.com"
# 엔터 3번 (기본값 사용)
```

### SSH 공개키 GitHub에 등록

```bash
# 공개키 출력
cat ~/.ssh/id_ed25519.pub
```

1. [GitHub Settings → SSH and GPG keys](https://github.com/settings/keys) 이동
2. **New SSH key** 클릭
3. 출력된 내용 전체 붙여넣기

### 연결 확인

```bash
ssh -T git@github.com
# Hi [username]! You've successfully authenticated.
```

---

## 7️⃣ 프로젝트 생성

환경 설치가 완료되면 채독스 프로젝트를 생성합니다.

```bash
# 원하는 경로로 이동
cd ~/projects  # 또는 원하는 폴더

# Rails 프로젝트 생성
rails new chatdox \
  --css tailwind \
  --database sqlite3 \
  --skip-test

# 생성된 폴더로 이동
cd chatdox

# 서버 실행
rails server
```

브라우저에서 [http://localhost:3000](http://localhost:3000) 접속 → Rails 기본 화면이 보이면 성공!

---

## 8️⃣ GitHub 리포지토리 연결

```bash
# Git 초기화 (이미 되어 있음)
git init

# 첫 커밋
git add .
git commit -m "Initial Rails project setup"

# GitHub에서 새 리포지토리 생성 후
git remote add origin git@github.com:[username]/chatdox.git
git branch -M main
git push -u origin main
```

---

## 🔍 환경 확인 최종 체크

모든 설치가 완료되면 아래 명령어로 한 번에 확인하세요:

```bash
git --version     # git version 2.x.x
ruby --version    # ruby 3.3.x
rails --version   # Rails 8.1.x
node --version    # v20.x.x 이상
```

---

## 🚨 자주 발생하는 문제

**`rails` 명령어를 찾을 수 없습니다**
```bash
gem install rails
# 이후 터미널 재시작
```

**`bundle install` 오류 (macOS)**
```bash
xcode-select --install
```

**포트 3000이 이미 사용 중입니다**
```bash
rails server -p 3001  # 다른 포트 사용
```

**Windows에서 `rails new` 오류**
```bash
# Gemfile에서 gem "tzinfo-data" 주석 해제 확인
```

**WSL에서 `rbenv install` 시 fiddle/psych 빌드 실패**
```bash
# libffi, libyaml 누락이 원인. 위 "빌드에 필요한 패키지 설치" 명령에
# libffi-dev libyaml-dev가 빠졌다면 추가 설치 후 재시도
sudo apt install -y libffi-dev libyaml-dev
rbenv install 3.3.6
```

---

## ✅ 챕터 3 체크리스트

- [ ] Ruby 3.3.x 설치 완료
- [ ] Rails 8.1.x 설치 완료
- [ ] Node.js LTS 설치 완료
- [ ] VS Code + 권장 확장 프로그램 설치
- [ ] GitHub SSH 연결 완료
- [ ] `rails new chatdox` 프로젝트 생성 완료
- [ ] `http://localhost:3000` 접속 성공
- [ ] GitHub 리포지토리 첫 커밋 완료

---

## ➡️ 다음 챕터

**[4. 랜딩페이지 구축 →](04_landing_page.md)**

> 환경 준비 완료! 이제 채독스의 첫 화면인 랜딩페이지를 만들어봅니다.
