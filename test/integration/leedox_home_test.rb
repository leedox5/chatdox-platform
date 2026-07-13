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

  test "Chatdox preserves the original landing sections" do
    get chatdox_path

    assert_response :success
    assert_select "h1", text: /웹서비스 구축 패키지/
    assert_select "h2", text: /완전한 커리큘럼/
    assert_select "h2", text: /상품 구성/
    assert_select "h2", text: /단품 구매 안내/
    assert_select "h2", text: /기술 스택/
    assert_select "h2", text: /자주 묻는 질문/
    assert_match(/평생 접근|1년 무료 업데이트|개인 학습·활용 라이선스|7일 이내 100% 환불/, response.body)
    assert_match(/검증 중인 가설 가격/, response.body)
    assert_no_match(/무료 체험|프리미엄형|오픈 알림/, response.body)
    assert_no_match(/선택형 운영 지원|커뮤니티 이용|라이브 오피스아워|코드리뷰 크레딧|아키텍처 클리닉/, response.body)
  end

  test "Claudox product page includes required structure and links into viewer" do
    get claudox_path

    assert_response :success
    assert_select "h1", text: /클로드가 들어온 날, 팀이 달라졌다/
    assert_match(/실제 구성과 목차/, response.body)
    assert_match(/포함 항목 \/ 미포함 항목/, response.body)
    assert_match(/FAQ/, response.body)
    assert_match(/9,900원/, response.body)
    assert_match(/검증 중인 가설/, response.body)
    assert_select "a[href=?]", claudox_read_path, text: /읽기 시작하기/
    assert_select "a[href=?]", claudox_chapter_path("01"), minimum: 1
  end

  test "Claudox product page marks chapter completion accurately against 88_progress.md" do
    get claudox_path

    assert_response :success
    assert_match(/완성\s*11\s*\/\s*20/, response.body)
    assert_match(/CH\s*01.*?>완성</m, response.body)
    assert_match(/CH\s*06.*?>준비 중</m, response.body)
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
    assert_response :redirect
  end
end
