ID: 0005
Title: docs/01_overview.md 기술 스택 표 렌더링 관련 후속 전달 메모
Date: 2026.07.12
Owner: Claudox

목적
- docs/curriculum 은 read-only 정책이므로, 그 내부 수정사항이 필요할 경우 curriculum 프로젝트로 전달하기 위한 기술 메모.

현재 판단
- 본 이슈의 직접 원인은 chatdox-platform 렌더링 경로의 sanitize/tailwind 설정에 있었음.
- docs/curriculum 원본 마크다운 자체 변경은 필수 아님.

curriculum 측 전달 필요 가능 항목(검토 요청)
1. 문서 가이드 정비
- Tailwind CSS v4 기준으로 typography 플러그인 적용 가이드를 명시할지 검토.
- v3 방식(npm + tailwind.config.js)과 혼동되지 않도록 안내 문구 정리.

2. Redcarpet 표 렌더링 주의사항 정리
- tables: true 옵션 필요성과 sanitize 허용 태그(table/thead/tbody/tr/th/td) 체크포인트를 가이드에 명시할지 검토.

3. subtree read-only 정책 안내 강화
- docs/curriculum 수정은 curriculum 프로젝트에서 처리 후 subtree pull 로 반영한다는 흐름을 문서화/강조.

chatdox-platform에서 확인된 기술 사실
- Redcarpet tables: true 는 이미 활성화되어 있었음.
- 기본 sanitize 는 table 관련 태그를 제거할 수 있어 표가 깨져 보일 수 있음.
- Tailwind v4에서는 application.css에 @plugin "@tailwindcss/typography" 방식 적용.

요청 사항
- 위 항목을 curriculum 저장소에서 검토하고, 필요시 해당 프로젝트에서 문서/가이드 업데이트 처리 요청.
