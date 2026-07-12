# Service Desk 사용법

유저, 팀원 등 관련된 자들의 요구사항을 정리하고 그 프로세스를 관리하기 위한 폴더.

## 범위

여기는 **명시적으로 접수된 요청**만 다룬다. `CLAUDE/` 챕터 시스템의 TOC 커버리지 규칙(모든 대화 내용을 챕터에 남긴다)과는 다르다 — 채팅에서 나눈 모든 이야기를 자동으로 여기에 트래킹할 필요는 없다. `new` 명령으로 직접 요청을 만들었을 때만 여기 남는다.

## 새 요청 만들기

터미널에서 `service-desk/` 안에 있는 스크립트를 실행하면 `_FORM.md`를 복사해 다음 ID로 새 요청을 만들어준다.

- Git Bash: `./new.sh` (또는 `bash new.sh`)
- PowerShell: `./new.ps1`

매번 전체 경로를 안 치고 `new` 한 마디로 실행하고 싶다면, 셸 프로필에 alias/함수를 등록하면 된다.

## 워크플로우

요청 파일은 상태에 따라 폴더를 이동한다.

```
01_new/         새로 접수된 요청
02_in_progress/ 처리 중인 요청
03_completed/   처리 완료된 요청
```

## 요청 파일 작성 형식

파일명은 `NNNN.md` (4자리 ID, 예: `0001.md`). `Description`과 `Job`은 요청자/Claudox가 여러 줄로 자유롭게 적는 부분이라, 그 내용만 `text` 코드펜스로 감싼다 — 감싸지 않으면 Markdown 렌더링 시 여러 줄이 한 문단으로 뭉개진다.

````text
         ID : 0001
       Date : YYYY.MM.DD
  Requester : 요청자 이름
    Subject : 한 줄 제목
     Status : New | In Progress | Completed

Description :
```text
요청 내용 상세 (여러 줄 가능)
```

Job :
```text
(완료 시 작성 — 무엇을, 어떻게 처리했는지)
```
````

- 새 요청은 `01_new/_FORM.md`를 복사해서 다음 ID 번호로 만든다 (직전 최대 ID + 1). `_FORM.md` 자체는 빈 템플릿이니 지우거나 번호를 매기지 않는다.
- 처리를 시작하면 `02_in_progress/`로 옮기고 `Status`를 갱신한다.
- 완료되면 `03_completed/`로 옮기고 `Status`를 `Completed`로, `Job`을 채운다.
- 요청은 삭제하지 않고 항상 `03_completed/`에 기록으로 남긴다.

## CLAUDE/99_service_desk.md와의 관계

이 폴더가 생기기 전에는 `CLAUDE/99_service_desk.md`(단일 파일, `REQ_NNNN>` 형식)에 요청을 기록했다. 이 폴더 구조가 그 자리를 대체하면서 파일은 제거됐고, 거기 있던 유일한 기록(REQ_0001, Free/Pro/Max 챕터 요청)은 `03_completed/0001.md`로 이관됐다.
