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
    assert_select "h2", text: /월 구독형 가격/
    assert_select "h2", text: /기술 스택/
    assert_select "h2", text: /자주 묻는 질문/
  end

  test "Claudox and existing core entry points remain reachable" do
    get claudox_path
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
