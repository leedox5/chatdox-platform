# 문제 해결

## Issue 1: 고객키 검증 에러

### 증상

```
"고객키는 영문 대소문자, 숫자, 특수문자 -, _, =, ., @로 2자 이상 50자 이하여야 합니다"
```

### 원인

`customerKey`가 1자였음 (user id가 1일 때 customerKey = "1")

### 해결

```ruby
# 변경 전
customer_key = current_user.id  # "1" → 에러!

# 변경 후
customer_key = "user-#{current_user.id}"  # "user-1" → 통과
```

**주의점:**
- 최소 2자 이상
- 영문, 숫자, 특수문자 (-, _, =, ., @) 만 허용
- 최대 50자

---

## Issue 2: API 개별 연동 키 사용 불가

### 증상

```
"결제위젯 연동 키의 클라이언트 키로 SDK를 연동해주세요. API 개별 연동 키는 지원하지 않습니다"
```

### 원인

API 개별 연동 키를 결제위젯에 사용함

### 해결

토스페이먼츠 개발자 센터에서 **결제위젯 연동 키**를 별도로 발급받아 사용

**토스 키 종류:**

| 키 종류 | 용도 | 발급 위치 |
|--------|------|----------|
| 결제위젯 연동 키 | 프론트엔드 결제위젯 | 결제위젯 연동 키 관리 |
| API 개별 연동 키 | 백엔드 API 호출 | API 개별 연동 |
| API 시크릿 | 백엔드 Basic Auth | API 개별 연동 |

---

## Issue 3: `Net::HTTP` 미로드

### 증상

```
uninitialized constant Net::HTTP
```

### 원인

`app/services/toss_payments/client.rb`에서 필요한 라이브러리를 require하지 않음

### 해결

파일 최상단에 추가:

```ruby
require 'net/http'
require 'json'
require 'base64'

module TossPayments
  class Client
    # ...
  end
end
```

**주의:**
- Rails는 자동으로 모든 라이브러리를 로드하지 않음
- 표준 라이브러리 사용 시 명시적으로 require 필요

---

## Issue 4: 라우팅 메서드 미스매치

### 증상

```
No route matches [GET] "/billing/success"
```

### 원인

`config/routes.rb`에서 `/billing/success`를 POST로 정의했으나, 토스 결제위젯에서 GET으로 리다이렉트함

### 해결

라우팅을 GET으로 변경:

```ruby
# 변경 전
post "/billing/success", to: "billing#success"

# 변경 후
get "/billing/success", to: "billing#success"
```

**토스페이먼츠 동작:**
1. 사용자가 결제 완료
2. 토스 서버에서 결제 승인
3. 토스가 클라이언트를 GET으로 `successUrl`로 리다이렉트
4. URL 파라미터: `?paymentKey=...&orderId=...&amount=...`

---

## Issue 5: 기본 인증 (Basic Auth) 구현

### 증상

결제 승인 API 호출 시 401 Unauthorized

### 원인

HTTP 헤더에 Basic Auth 형식의 Authorization 헤더가 없음

### 해결

Base64 인코딩으로 구현:

```ruby
def auth_header
  credentials = "#{ENV['TOSS_SECRET_KEY']}:"
  encoded = Base64.strict_encode64(credentials)
  "Basic #{encoded}"
end

# 헤더 설정
headers = {
  "Authorization" => auth_header,
  "Content-Type" => "application/json"
}
```

**포맷:**
- `{API_SECRET}:` (콜론 포함)
- Base64로 인코딩
- `Authorization: Basic {encoded_value}` 형식으로 전송

---

## Issue 6: CSRF 검증 건너뛰기

### 증상

웹훅 엔드포인트로 POST 요청이 CSRF 에러로 거절됨

### 원인

웹훅은 외부 서비스에서 보내므로 CSRF 토큰이 없음

### 해결

```ruby
class Webhooks::TossPaymentsController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def create
    # 대신 웹훅 시그니처 검증
  end
end
```

**보안:**
- CSRF 검증을 건너뛰되
- 웹훅 시그니처 (HMAC) 검증 필수
