require "test_helper"

class GithubAccessManagementTest < ActionDispatch::IntegrationTest
  KST = License::KST

  setup do
    Commerce::CatalogBootstrap.call!
    @product = Product.find_by!(code: "chatdox")
    @user = User.create!(name: "테스트 유저", email: "github-customer@example.com", password: "password123", created_at: 30.days.ago)
    @admin = User.create!(name: "테스트 유저", email: "github-admin@example.com", password: "password123", role: :admin)
  end

  test "customer can register one GitHub username and a second attempt is rejected" do
    sign_in(@user)

    assert_difference "ExternalAccountLink.count", 1 do
      post github_access_path, params: { external_account_link: { username: "  @Octo-Cat " } }
    end
    assert_redirected_to github_access_path

    link = ExternalAccountLink.order(:created_at).last
    assert_equal @user, link.user
    assert_equal "github", link.provider
    assert_equal "Octo-Cat", link.username
    assert_equal "octo-cat", link.normalized_username
    assert_nil link.invited_at
    assert_nil link.revoked_at

    assert_no_difference "ExternalAccountLink.count" do
      post github_access_path, params: { external_account_link: { username: "another-name" } }
    end
    assert_redirected_to github_access_path
    assert_equal "이미 연결된 GitHub 계정이 있습니다.", flash[:alert]

    get github_access_path
    assert_response :success
    assert_match(/@Octo-Cat/, response.body)
  end

  test "customer submission ignores forged ownership and timestamp fields" do
    other = User.create!(name: "테스트 유저", email: "github-other@example.com", password: "password123")
    sign_in(@user)

    post github_access_path, params: {
      external_account_link: { username: "forged-user", user_id: other.id, invited_at: 1.day.ago }
    }

    link = ExternalAccountLink.order(:created_at).last
    assert_equal @user, link.user
    assert_nil link.invited_at
  end

  test "admin invite and revoke lists follow license state and complete buttons only touch their own timestamp" do
    license = create_license(user: @user, active: true)
    link = ExternalAccountLink.create!(user: @user, username: "lab-user")

    get admin_commerce_github_access_path
    assert_redirected_to new_user_session_path

    sign_in(@user)
    get admin_commerce_github_access_path
    assert_redirected_to root_path
    delete destroy_user_session_path

    sign_in(@admin)
    get admin_commerce_github_access_path
    assert_response :success
    assert_match(/lab-user/, response.body)

    patch admin_commerce_invite_github_access_path(link.public_id)
    assert_redirected_to admin_commerce_github_access_path
    link.reload
    assert link.invited_at.present?
    assert_nil link.revoked_at

    get admin_commerce_github_access_path
    assert_no_match(/lab-user/, response.body)

    license.update!(status: "canceled")

    get admin_commerce_github_access_path
    assert_match(/lab-user/, response.body)

    patch admin_commerce_revoke_github_access_path(link.public_id)
    link.reload
    assert link.revoked_at.present?
    assert link.invited_at.present?, "revoke must not clear invited_at"

    get admin_commerce_github_access_path
    assert_no_match(/lab-user/, response.body)
  end

  test "link without an active license never appears in either admin list" do
    ExternalAccountLink.create!(user: @user, username: "no-license-user")
    sign_in(@admin)

    get admin_commerce_github_access_path
    assert_response :success
    assert_no_match(/no-license-user/, response.body)
  end

  private

  def sign_in(user)
    post user_session_path, params: { user: { email: user.email, password: "password123" } }
  end

  def create_license(user:, active:)
    today = Time.current.in_time_zone(KST).to_date
    start_on = active ? today : today - 2.months
    last_on = start_on + 1.month - 1.day
    License.create!(
      user: user, product: @product, source: "paid", status: "active",
      starts_on: start_on, last_usable_on: last_on,
      access_ends_at: KST.local((last_on + 1.day).year, (last_on + 1.day).month, (last_on + 1.day).day)
    )
  end
end
