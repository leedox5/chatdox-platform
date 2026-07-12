---
title: ".gitignore 폴더 규칙과 .gitkeep의 역할"
date: "2026-07-12"
category: "Git"
difficulty: "초급"
related: ["service-desk/GUIDE.md", ".gitignore"]
---

# .gitignore 폴더 규칙과 .gitkeep의 역할

`service-desk/_screen_shot/` 폴더를 커밋에서 제외하면서, 함께 알아두면 좋은 두 가지 — 폴더 단위 `.gitignore` 규칙과 `.gitkeep`의 용도를 정리합니다.

---

## 🎯 이 팁을 읽어야 하는 경우

- 로그/스크린샷처럼 커밋하면 안 되는 폴더가 새로 생겼다
- `git status`에 빈 폴더가 안 보여서 당황했다
- `.gitkeep`이라는 빈 파일을 봤는데 용도를 모르겠다

---

## 📋 배경: 왜 `_screen_shot/`을 통째로 무시하나

`service-desk/`에 요청을 처리하다 보면 스크린샷이나 로그를 임시로 쌓아두는 폴더가 필요할 수 있습니다. 개별 파일 확장자(`*.png`, `*.log`)는 이미 `.gitignore`에 있었지만, 폴더 자체를 명시하면 안에 어떤 파일이 들어오든(확장자가 뭐든) 한 번에 제외할 수 있습니다.

```gitignore
# 로그/스크린샷 폴더 (예: service-desk/_screen_shot/), 커밋 대상 아님
_screen_shot/
```

패턴 끝의 `/`는 "이 이름의 폴더"라는 뜻입니다. 폴더로 지정하면 하위 파일 확장자를 일일이 나열할 필요가 없습니다.

**확인 방법:**
```bash
git check-ignore -v service-desk/_screen_shot/아무파일.png
# → .gitignore:52:_screen_shot/  service-desk/_screen_shot/아무파일.png
```

---

## ✅ `.gitkeep`은 무엇인가

Git은 **파일만 추적**하고, 빈 디렉토리는 아예 추적하지 않습니다. 그래서 폴더 안에 파일이 하나도 없으면:

- `git add .`를 해도 아무 일도 일어나지 않는다
- 커밋해도 그 폴더는 저장소에 안 남는다
- 다른 사람이 clone하면 그 폴더 자체가 존재하지 않는다

`service-desk/02_in_progress/`처럼 "지금은 비어있지만 구조상 폴더는 존재해야 하는" 경우, 폴더 안에 내용 없는 파일 하나를 넣어서 git이 추적할 대상을 만들어줍니다. 그 파일의 이름을 관례적으로 `.gitkeep`이라고 부릅니다.

**중요:** `.gitkeep`은 Git이 인식하는 특별한 파일명이 **아닙니다.** 그냥 이름일 뿐이고, 어떤 이름을 써도 동작은 같습니다 (`.keep`, `.gitignore`가 아니면 뭐든 상관없음). "비어있는 폴더를 유지하려고 넣어둔 파일"이라는 관례가 이 이름에 붙어 있을 뿐입니다.

```bash
touch service-desk/02_in_progress/.gitkeep
```

폴더에 실제 파일(예: 요청 티켓)이 들어오면 `.gitkeep`은 지워도 되고, 그냥 둬도 무방합니다.

---

## 🤔 자주 묻는 질문

**Q: `_screen_shot/`처럼 폴더째로 막지 않고 확장자로만 막으면 안 되나요?**
A: 됩니다. 다만 로그 폴더처럼 안에 뭐가 들어올지 예측하기 어려울 때는, 폴더 단위로 막는 쪽이 유지보수하기 편합니다.

**Q: `.gitkeep` 대신 `README.md`를 넣어도 되나요?**
A: 됩니다. 목적은 "폴더 안에 파일이 하나 있게 만드는 것"뿐이라, 그 폴더의 용도를 설명하는 파일이면 오히려 더 좋습니다.

**Q: 이미 `.gitignore`로 막힌 폴더에 `.gitkeep`을 넣으면요?**
A: `.gitkeep` 자체가 `.gitignore` 규칙에 걸리지 않는지 확인해야 합니다. `_screen_shot/`처럼 폴더 전체를 막았다면 그 안의 `.gitkeep`도 함께 무시되니, 이런 경우엔 애초에 `.gitkeep`을 넣을 필요가 없습니다 (폴더 자체를 커밋할 필요가 없으니까요).

---

## 🔗 관련 문서

- [service-desk/GUIDE.md](../service-desk/GUIDE.md) — `02_in_progress/`가 비어있을 때 `.gitkeep`을 쓰는 실제 사례
- [.gitignore](../.gitignore) — 이 저장소의 전체 무시 규칙
