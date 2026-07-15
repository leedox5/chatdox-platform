require "test_helper"

class LeedoxHomeTest < ActionDispatch::IntegrationTest
  test "integrated home presents LEEDOX and both products without unconfirmed pricing" do
    get root_path

    assert_response :success
    assert_select "title", text: /LEEDOX/
    assert_select "header a[href=?]", root_path, text: /LEEDOX/
    assert_select "h1", text: /AI와 함께 일하는 방법을/
    assert_select "a[href=?]", chatdox_path, minimum: 1
    assert_select "a[href=?]", claudox_path, minimum: 1
    assert_select "a[href='#products']", minimum: 2
    assert_select "footer a[href=?]", terms_path
    assert_select "footer a[href=?]", privacy_path
    assert_no_match(/₩|9,900원|무료 체험|프리미엄 요금제/, response.body)
  end

  test "guest header keeps authentication actions on desktop and mobile" do
    get root_path

    assert_response :success
    assert_select "a[href=?]", new_user_session_path, text: "로그인", count: 2
    assert_select "a[href=?]", new_user_registration_path, text: "회원가입", count: 2
    assert_select "nav[aria-label='모바일 내비게이션']"
  end

  test "guest and signed-in top navigation has no standalone docs entry and hides service desk" do
    get root_path
    assert_response :success
    assert_select "header nav[aria-label='주요 내비게이션'] a[href=?]", docs_path, count: 0
    assert_select "nav[aria-label='모바일 내비게이션'] a[href=?]", docs_path, count: 0
    assert_select "a[href=?]", service_desk_path, count: 0

    user = User.create!(email: "nav-user@example.com", password: "password123")
    post user_session_path, params: { user: { email: user.email, password: "password123" } }

    get root_path
    assert_response :success
    assert_select "header nav[aria-label='주요 내비게이션'] a[href=?]", docs_path, count: 0
    assert_select "nav[aria-label='모바일 내비게이션'] a[href=?]", docs_path, count: 0
    assert_select "a[href=?]", service_desk_path, count: 0
  end

  test "admin navigation keeps a working service desk link" do
    admin = User.create!(email: "nav-admin@example.com", password: "password123", role: :admin)
    post user_session_path, params: { user: { email: admin.email, password: "password123" } }

    get root_path

    assert_response :success
    assert_select "a[href=?]", service_desk_path, minimum: 1
  end

  test "mobile menu details element is wired to close on outside tap via Stimulus" do
    get root_path

    assert_response :success
    assert_select "details[data-controller='mobile-menu']"
  end

  test "service desk blocks guests and non-admin users but allows admins" do
    request = ServiceDeskRequest.create!(request_number: 5001, requester: "Tester", subject: "Guard check", description: "body", visibility: :visible)

    get service_desk_path
    assert_response :redirect
    assert_redirected_to new_user_session_path

    get service_desk_request_path(request)
    assert_response :redirect
    assert_redirected_to new_user_session_path

    user = User.create!(email: "sd-user@example.com", password: "password123")
    post user_session_path, params: { user: { email: user.email, password: "password123" } }

    get service_desk_path
    assert_response :redirect
    assert_redirected_to root_path

    delete destroy_user_session_path

    admin = User.create!(email: "sd-admin@example.com", password: "password123", role: :admin)
    post user_session_path, params: { user: { email: admin.email, password: "password123" } }

    get service_desk_path
    assert_response :success

    get service_desk_request_path(request)
    assert_response :success
  end

  test "service desk hides Private-visibility requests from index and direct show access" do
    visible_request = ServiceDeskRequest.create!(request_number: 5002, requester: "Tester", subject: "Public ticket should show", visibility: :visible)
    private_request = ServiceDeskRequest.create!(request_number: 5003, requester: "Tester", subject: "Private ticket should stay hidden", visibility: :restricted)

    admin = User.create!(email: "sd-admin-vis@example.com", password: "password123", role: :admin)
    post user_session_path, params: { user: { email: admin.email, password: "password123" } }

    get service_desk_path
    assert_response :success
    assert_match(/Public ticket should show/, response.body)
    assert_no_match(/Private ticket should stay hidden/, response.body)

    get service_desk_request_path(private_request)
    assert_response :not_found

    get service_desk_request_path(visible_request)
    assert_response :success
  end

  test "service desk request page renders description/job sections and links to neighboring requests" do
    first = ServiceDeskRequest.create!(request_number: 5004, requester: "Tester", subject: "First ticket", description: "First body", status: :confirmed, visibility: :visible)
    second = ServiceDeskRequest.create!(request_number: 5005, requester: "Tester", subject: "Second ticket", description: "Second body", visibility: :visible)
    first.service_desk_jobs.create!(author: "Claudox", content: "Did the work")

    admin = User.create!(email: "sd-admin-render@example.com", password: "password123", role: :admin)
    post user_session_path, params: { user: { email: admin.email, password: "password123" } }

    get service_desk_request_path(first)

    assert_response :success
    assert_no_match(/```/, response.body)
    assert_select "h2", text: "Description"
    assert_select "h2", text: "Job"
    assert_select "article", text: /Confirmed/
    assert_match(/Did the work/, response.body)
    assert_select "a[href=?]", service_desk_request_path(second), minimum: 1
  end

  test "service desk list stays visible without a desktop-only breakpoint (mobile regression)" do
    ServiceDeskRequest.create!(request_number: 5006, requester: "Tester", subject: "Mobile visible ticket", visibility: :visible)

    admin = User.create!(email: "sd-admin-mobile@example.com", password: "password123", role: :admin)
    post user_session_path, params: { user: { email: admin.email, password: "password123" } }

    get service_desk_path

    assert_response :success
    assert_no_match(/hidden lg:block/, response.body)
    assert_select "a", text: /Mobile visible ticket/
  end

  test "admin can publish a new ticket via the web form and it gets an auto-numbered request_number" do
    admin = User.create!(email: "sd-admin-create@example.com", password: "password123", role: :admin)
    post user_session_path, params: { user: { email: admin.email, password: "password123" } }

    get new_service_desk_request_path
    assert_response :success

    assert_difference "ServiceDeskRequest.count", 1 do
      post service_desk_path, params: { service_desk_request: { subject: "New web ticket", requester: "Tommy", visibility: "visible", description: "Filed from the web form" } }
    end

    created = ServiceDeskRequest.order(:request_number).last
    assert_equal "New web ticket", created.subject
    assert_redirected_to service_desk_request_path(created)

    follow_redirect!
    assert_match(/New web ticket/, response.body)
  end

  test "admin can add a job entry via the web form with auto-numbered job_number" do
    request = ServiceDeskRequest.create!(request_number: 5007, requester: "Tester", subject: "Job target", visibility: :visible)

    admin = User.create!(email: "sd-admin-job@example.com", password: "password123", role: :admin)
    post user_session_path, params: { user: { email: admin.email, password: "password123" } }

    assert_difference "request.service_desk_jobs.count", 1 do
      post service_desk_request_jobs_path(request), params: { service_desk_job: { author: "Tommy", content: "Investigated and fixed" } }
    end

    job = request.service_desk_jobs.order(:job_number).last
    assert_equal 1, job.job_number
    assert_redirected_to service_desk_request_path(request)

    follow_redirect!
    assert_match(/Investigated and fixed/, response.body)
  end

  test "service desk export downloads a zip of all requests" do
    ServiceDeskRequest.create!(request_number: 5008, requester: "Tester", subject: "Export me", visibility: :visible)

    admin = User.create!(email: "sd-admin-export@example.com", password: "password123", role: :admin)
    post user_session_path, params: { user: { email: admin.email, password: "password123" } }

    post service_desk_export_path

    assert_response :success
    assert_equal "application/zip", response.media_type
    assert response.body.start_with?("PK"), "expected a zip file signature"
  end

  test "service desk API rejects requests without a valid bearer token" do
    original_token = ENV["SERVICE_DESK_API_TOKEN"]
    ENV["SERVICE_DESK_API_TOKEN"] = "test-token-123"

    post service_desk_api_requests_path, params: { subject: "No auth", requester: "Agent" }
    assert_response :unauthorized

    post service_desk_api_requests_path, params: { subject: "Wrong token", requester: "Agent" },
                                          headers: { "Authorization" => "Bearer wrong-token" }
    assert_response :unauthorized
  ensure
    ENV["SERVICE_DESK_API_TOKEN"] = original_token
  end

  test "service desk API creates requests and jobs for AI agents with a valid bearer token" do
    original_token = ENV["SERVICE_DESK_API_TOKEN"]
    ENV["SERVICE_DESK_API_TOKEN"] = "test-token-123"
    auth_headers = { "Authorization" => "Bearer test-token-123" }

    assert_difference "ServiceDeskRequest.count", 1 do
      post service_desk_api_requests_path, params: { subject: "Agent-filed ticket", requester: "Claudox", visibility: "visible", description: "Filed via API" },
                                            headers: auth_headers
    end
    assert_response :created
    body = JSON.parse(response.body)
    request = ServiceDeskRequest.find_by(request_number: body["request_number"])
    assert_equal "Agent-filed ticket", request.subject

    assert_difference "request.service_desk_jobs.count", 1 do
      post service_desk_api_request_jobs_path(request_id: request.request_number), params: { author: "Claudox", content: "Handled via API" },
                                                                                    headers: auth_headers
    end
    assert_response :created
    job_body = JSON.parse(response.body)
    assert_equal "Handled via API", job_body["content"]
    assert_equal 1, job_body["job_number"]
  ensure
    ENV["SERVICE_DESK_API_TOKEN"] = original_token
  end

  test "signed in header keeps account identity and sign out actions" do
    user = User.create!(email: "home-test@example.com", password: "password123")
    post user_session_path, params: { user: { email: user.email, password: "password123" } }

    get root_path

    assert_response :success
    assert_select "header", text: /home-test@example.com/
    assert_select "a[href=?][data-turbo-method='delete']", destroy_user_session_path, text: "로그아웃", count: 2
    assert_select "a[href=?]", mypage_path, minimum: 1
    assert_select "a[href=?]", new_user_session_path, count: 0
  end

  test "Chatdox presents fixed-term VAT-inclusive prices without a purchase path" do
    get chatdox_path

    assert_response :success
    assert_select "h1", text: /웹서비스 구축 패키지/
    assert_select "h2", text: /완전한 커리큘럼/
    assert_select "h2", text: /상품 구성/
    assert_select "h2", text: /기간별 이용 안내/
    assert_select "h2", text: /기술 스택/
    assert_select "h2", text: /자주 묻는 질문/
    assert_match(/7,700원/, response.body)
    assert_match(/23,100원/, response.body)
    assert_match(/41,580원/, response.body)
    assert_match(/73,920원/, response.body)
    assert_match(/VAT 포함/, response.body)
    assert_match(/자동 갱신 없는 기간제 선불 라이선스/, response.body)
    assert_match(/구매 준비 중/, response.body)
    assert_no_match(/9,900원|평생 접근|1년 무료 업데이트|7일 이내 100% 환불|언제든 취소|월 구독/, response.body)
    assert_no_match(/무료 체험|프리미엄형|오픈 알림/, response.body)
    assert_no_match(/선택형 운영 지원|커뮤니티 이용|라이브 오피스아워|코드리뷰 크레딧|아키텍처 클리닉/, response.body)
    assert_select "a[href=?]", docs_path, text: /커리큘럼 문서 보기/
    assert_select "a[href=?]", billing_checkout_path, count: 0
  end

  test "Claudox product page includes required structure and links into viewer" do
    get claudox_path

    assert_response :success
    assert_select "h1", text: /클로드가 들어온 날, 팀이 달라졌다/
    assert_match(/실제 구성과 목차/, response.body)
    assert_match(/포함 항목 \/ 미포함 항목/, response.body)
    assert_match(/FAQ/, response.body)
    assert_match(/판매 준비 중/, response.body)
    assert_no_match(/9,900원|평생 접근|1년 무료 업데이트|7일 이내 100% 환불/, response.body)
    assert_select "a[href=?]", claudox_read_path, text: /읽기 시작하기/
    assert_select "a[href=?]", claudox_chapter_path("01"), minimum: 1
    assert_select "a[href=?]", billing_checkout_path, count: 0
  end

  test "signed-in product pages also keep the legacy checkout link hidden" do
    user = User.create!(email: "policy-user@example.com", password: "password123")
    post user_session_path, params: { user: { email: user.email, password: "password123" } }

    [ chatdox_path, claudox_path ].each do |path|
      get path
      assert_response :success
      assert_select "a[href=?]", billing_checkout_path, count: 0
    end
  end

  test "legacy checkout is a server-rendered inactive screen for guests and users" do
    assert_no_difference [ "Subscription.count", "PaymentTransaction.count" ] do
      get billing_checkout_path
    end

    assert_response :success
    assert_match(/신규 결제를 준비하고 있습니다/, response.body)
    assert_match(/결제나 결제 수단 등록을 시작할 수 없습니다/, response.body)
    assert_select "#pay-button", count: 0
    assert_select "script[src*='tosspayments']", count: 0
    assert_select "script[src*='portone']", count: 0

    user = User.create!(email: "checkout-blocked@example.com", password: "password123")
    post user_session_path, params: { user: { email: user.email, password: "password123" } }

    assert_no_difference [ "Subscription.count", "PaymentTransaction.count" ] do
      get billing_checkout_path
    end
    assert_response :success
    assert_match(/신규 결제를 준비하고 있습니다/, response.body)
  end

  test "billing auth endpoint is blocked without issuing a billing key" do
    assert_no_difference [ "Subscription.count", "PaymentTransaction.count" ] do
      post billing_auths_path, params: { authKey: "must-not-be-used", billingKey: "must-not-be-used" }
    end

    assert_response :see_other
    assert_redirected_to chatdox_path
  end

  test "Claudox product page marks chapter completion accurately against source chapter files" do
    placeholder = ClaudoxProductsController::UNWRITTEN_PLACEHOLDER
    chapter_file = ->(id) { Dir.glob(ClaudoxProductsController::CLAUDOX_PATH.join("#{id}_*.md")).sort.first }
    written_count = (1..20).count { |n| (file = chapter_file.call(n.to_s.rjust(2, "0"))) && !File.read(file).include?(placeholder) }
    incomplete_id = (1..20).find { |n| (file = chapter_file.call(n.to_s.rjust(2, "0"))) && File.read(file).include?(placeholder) }

    get claudox_path

    assert_response :success
    assert_match(/완성\s*#{written_count}\s*\/\s*20/, response.body)
    assert_match(/CH\s*01.*?>완성</m, response.body)
    assert_match(/CH\s*#{incomplete_id.to_s.rjust(2, "0")}.*?>준비 중</m, response.body) if incomplete_id
  end

  test "Claudox and existing core entry points remain reachable" do
    get claudox_path
    assert_response :success

    get claudox_read_path
    assert_response :success

    get claudox_chapter_path("01")
    assert_response :success

    get docs_path
    assert_response :success

    get new_user_session_path
    assert_response :success

    get dashboard_path
    assert_response :redirect

    get billing_checkout_path
    assert_response :success
    assert_match(/신규 결제를 준비하고 있습니다/, response.body)
  end
end
