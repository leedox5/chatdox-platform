# Commerce 배포·Sandbox·판매 중단 Runbook

이 문서는 Product·Order·License 기반을 배포하고 Sandbox에서 검증하기 위한 운영 절차다. 운영 판매는 Product Owner의 별도 승인 전까지 비활성으로 유지한다. 명령의 placeholder는 승인된 secret store와 배포 시스템에서 주입하며 문서, shell history, ticket, 채팅, 로그에 실제 값을 기록하지 않는다.

## 1. 배포 전 확인

1. 운영 DB snapshot/backup의 생성 시각과 복구 가능 상태를 확인한다.
2. 현재 전역 commerce gate와 Chatdox 상품 gate가 모두 닫혀 있는지 읽기 전용으로 확인한다.
3. Claudox가 판매 비활성이고 Offer가 0개인지 확인한다.
4. 작업 브랜치, 배포 commit, migration 목록과 담당 승인자를 기록한다.
5. 실제 고객 데이터나 운영 결제수단을 Sandbox 검증에 사용하지 않는다.

```sh
bin/rails commerce:preflight PROVIDER=<sandbox-provider>
bin/rails commerce:reconcile
bin/rails db:migrate:status
```

## 2. Migration과 catalog

판매 gate가 닫힌 상태에서 다음 순서로 진행한다.

```sh
bin/rails db:migrate
bin/rails db:seed
bin/rails runner 'puts Product.order(:code).pluck(:code, :sale_enabled).inspect; puts ProductOffer.order(:code).pluck(:code, :total_amount, :currency).inspect'
```

출력에서 상품 code 2개, Chatdox Offer 4개, Claudox Offer 0개와 승인된 catalog 금액을 대조한다. 운영자의 기존 active/판매 기간 값은 bootstrap이 덮어쓰지 않으므로 별도로 확인한다.

## 3. PG 환경과 URL

credential은 승인된 secret store에서 환경변수로만 주입한다. 값 자체를 출력하는 명령은 사용하지 않는다.

Toss 확인 이름:

- `TOSS_CLIENT_KEY`
- `TOSS_SECRET_KEY`
- `TOSS_WEBHOOK_SECRET`

PortOne 확인 이름:

- `PORTONE_API_SECRET`
- `PORTONE_STORE_ID`
- `PORTONE_CHANNEL_KEY`
- `PORTONE_WEBHOOK_SECRET`

공통 provider 선택 이름은 `PAYMENT_PROVIDER`다. callback/return URL은 `/billing/success`, 취소 URL은 `/billing/cancel`, webhook URL은 `/webhooks/toss_payments`와 `/webhooks/portone`이다. 외부 PG Console에 등록한 HTTPS host와 배포 host가 일치하는지 확인한다.

```sh
bin/rails commerce:preflight PROVIDER=<sandbox-provider>
```

`provider_configuration=passed`가 아니면 판매 gate를 열지 않는다.

### 3-1. PortOne 미승인 구간의 무통장입금 fallback

PortOne 자체 승인(채널 심사 결과 대기 등)이 아직 끝나지 않은 상태에서도, `Product.sale_enabled`만 켜져 있으면 체크아웃은 자동으로 무통장입금 경로(provider `manual`)로 열린다 — PortOne이 `provider_configuration=passed` 상태가 되면 다음 결제부터 자동으로 PortOne으로 돌아간다(둘 중 하나를 명시적으로 고르는 UI는 없다).

- `BANK_TRANSFER_ACCOUNT_INFO` — 주문 확인 화면에 그대로 노출되는 입금 계좌 안내 문구(줄바꿈 가능). 실제 계좌 정보는 이 문서·커밋·티켓에 남기지 않고 secret store에서 직접 주입한다.
- 입금 확인은 전적으로 수동이다: `/admin/commerce/orders/:id`에서 관리자가 실제 입금을 확인한 뒤 "입금 확인" 액션을 눌러야 라이선스가 발급된다. 자동 확인/자동 취소는 없다.

## 4. 자동 테스트와 대조

```sh
bin/rails test
bin/rails zeitwerk:check
bin/rubocop
bin/rails commerce:reconcile
```

실패가 있거나 대조 결과가 `anomaly`면 Sandbox smoke test와 판매 활성화를 중단한다. 기존 범위의 정적 검사 예외가 있다면 신규 변경과 분리해 승인 기록을 남긴다.

## 5. Sandbox smoke test

격리된 Sandbox 환경에서만 전역 gate와 Chatdox 상품 gate를 승인된 임시 값으로 연다. Claudox는 변경하지 않는다.

각 provider에 대해 전용 test 계정과 Sandbox 결제수단으로 다음을 확인한다.

1. checkout에서 VAT 포함 Offer 금액과 기간 확인
2. pending Order 생성 확인
3. 성공 후 paid Order, PaymentTransaction 1개, License 1개, Subscription 0개 확인
4. 결제창 취소와 승인 실패에서 License 0개 확인
5. callback/return 및 webhook 재전송 확인
6. callback 선행과 webhook 선행 순서 모두 확인
7. Dashboard의 상품별 License 확인
8. `bin/rails commerce:reconcile` 결과 정상 확인

Sandbox가 끝나면 임시 Order·License를 승인된 test-data 절차로 정리하고 두 gate를 다시 닫는다. webhook credential과 route는 유지한다.

## 6. 운영 배포 후 비활성 smoke test

운영 배포 직후에도 판매 gate를 열지 않는다.

1. `/chatdox`, `/claudox`, `/billing/checkout`을 desktop/mobile에서 확인한다.
2. checkout이 준비 중 화면이고 PG SDK를 로드하지 않는지 확인한다.
3. 기존 문서·인증·Dashboard가 정상인지 확인한다.
4. callback/webhook route가 존재하고 secret 검증 없이 이벤트를 처리하지 않는지 확인한다.
5. migration 상태와 정합성 대조 결과를 보관한다.

## 7. Product Owner 승인 후 판매 활성

다음 증거가 모두 있을 때만 별도 변경 승인으로 진행한다.

- 양 PG Sandbox 시나리오 결과
- 전체 테스트와 정합성 대조 정상
- 운영 backup과 배포 상태 정상
- 약관·환불·고객지원 준비 확인
- Product Owner의 명시적 판매 승인

배포 시스템에서 전역 gate를 `<approved-commerce-flag>`로 설정하고, 별도 승인된 runner에서 Chatdox 상품 gate를 `<approved-product-sale-state>`로 변경한다. 실제 값과 명령은 승인 ticket의 secret이 아닌 변경 절차에만 보관한다. Claudox는 변경하지 않는다.

활성 직후 첫 주문은 public Order ID, provider, 상태, 시각만으로 다음을 확인한다.

- pending 생성
- PG 승인 검증
- paid 전이와 PaymentTransaction 1개
- License 1개와 Subscription 0개
- callback/webhook 중복 후 count 유지
- 정합성 대조 정상

## 8. 신규 판매 긴급 중단

가장 먼저 checkout만 중단하고 callback/webhook 처리는 계속 유지한다.

1. 배포 시스템에서 전역 commerce gate를 `<disabled-commerce-flag>`로 변경한다.
2. 필요하면 Chatdox 상품 gate도 승인된 비활성 상태로 변경한다.
3. application process를 정상 재시작한다.
4. `/billing/checkout`이 준비 중 화면인지 확인한다.
5. 이미 PG로 이동한 주문을 위해 `/billing/success`와 webhook route, PG credential은 제거하지 않는다.
6. pending Order와 PG 상태를 대조하고 `commerce:reconcile`을 실행한다.

credential 삭제나 webhook route 차단은 긴급 판매 중단 수단으로 사용하지 않는다. 그러면 이미 승인된 결제의 확정·복구가 막힌다.

## 9. 장애 증거와 수동 복구 승인

수집 가능한 최소 증거:

- event 이름
- provider
- Order public ID
- Order/PaymentTransaction/License 상태와 시각
- PG 관리 화면의 성공·실패 상태(카드·고객 개인정보 제외)
- callback/webhook 수신 시각과 HTTP 상태
- `commerce:reconcile` issue code

secret, 전체 provider payload, 이메일, 카드정보를 ticket과 로그에 복사하지 않는다.

PG 성공 후 DB 확정 실패는 다음 순서로 처리한다.

1. 신규 판매를 중단한다.
2. Order가 pending이고 부분 License가 없는지 대조한다.
3. PG의 결제 성공을 승인된 관리 화면에서 확인한다.
4. 같은 callback/webhook의 안전한 재전송을 우선 사용한다.
5. 재전송으로 복구되지 않으면 개발·운영 2인 승인 후 별도 복구 작업을 작성한다.
6. 직접 SQL 수정, 자동 환불, License 수동 생성은 별도 승인 없이 수행하지 않는다.
7. 복구 후 count와 정합성 대조를 다시 확인한다.

## 10. Rollback과 forward-fix

신규 Order 기반 거래가 한 건이라도 생성된 뒤에는 commerce migration을 단순 rollback하지 않는다. rollback은 nullable `subscription_id`를 다시 NOT NULL로 만들고 Order·OrderItem·License 원장을 삭제할 수 있다.

다음 경우 forward-fix를 선택한다.

- PG에는 성공했지만 DB 원장이 확정되지 않은 주문이 있음
- 신규 PaymentTransaction의 `subscription_id`가 null임
- License 또는 Order snapshot을 보존해야 함
- rolling 배포 중 구·신 코드가 함께 실행 중임

schema 결함은 보존 migration으로 수정하고, 데이터 복구는 별도 승인된 idempotent 작업으로 수행한다. rollback 필요성이 있으면 먼저 판매 중단, backup, 영향 Order 목록, 복구 rehearsal과 Product Owner 승인을 확보한다.
