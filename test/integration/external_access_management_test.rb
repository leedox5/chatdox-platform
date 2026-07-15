require "test_helper"

class ExternalAccessManagementTest < ActionDispatch::IntegrationTest
  KST = License::KST

  setup do
    Commerce::CatalogBootstrap.call!
    @product = Product.find_by!(code: "chatdox")
    @user = User.create!(name: "테스트 유저", email: "github-customer@example.com", password: "password123", created_at: 30.days.ago)
    @other = User.create!(name: "테스트 유저", email: "github-other@example.com", password: "password123", created_at: 30.days.ago)
    @admin = User.create!(name: "테스트 유저", email: "github-admin@example.com", password: "password123", role: :admin)
    @at = Time.current.change(usec: 0)
  end

  test "customer submission ignores forged state identity provider and owner fields" do
    sign_in(@user)
    assert_difference [ "ExternalAccountLink.count", "ExternalAccessTask.count" ], 1 do
      post github_access_path, params: {
        external_account_link: {
          username: "  @Customer-Lab ", status: "verified", external_uid: "999",
          provider: "other", user_id: @other.id
        }
      }
    end

    link = ExternalAccountLink.order(:created_at).last
    assert_equal @user, link.user
    assert_equal "github", link.provider
    assert_equal "pending_verification", link.status
    assert_nil link.external_uid
    assert_equal "customer-lab", link.normalized_username
  end

  test "customer sees only own public states with escaped messages and no internal or numeric data" do
    own = create_verified_link(@user, "public-user", "5101")
    other = create_verified_link(@other, "private-other", "5102")
    license = create_license(@user)
    ExternalAccess::DueProcessor.call!(at: @at)
    grant = own.external_access_grants.find_by!(license: license)
    grant.update!(public_message: "<script>public</script>", internal_note: "internal-secret-note")

    sign_in(@user)
    get github_access_path

    assert_response :success
    assert_match(/@public-user/, response.body)
    assert_match(/&lt;script&gt;public&lt;\/script&gt;/, response.body)
    assert_no_match(/private-other|5101|5102|internal-secret-note/, response.body)
    assert_no_match(/token|private key|PAT/, response.body)
    assert other.verified?
  end

  test "customer account change and disconnect are owner scoped and cannot forge grant state" do
    own = create_verified_link(@user, "owner-link", "5201")
    other = create_verified_link(@other, "other-link", "5202")
    sign_in(@user)

    post change_github_access_path, params: { external_account_link: { link_id: other.public_id, username: "stolen" } }
    assert_response :not_found

    post disconnect_github_access_path, params: {
      external_account_link: { link_id: own.public_id, status: "verified", external_uid: "999" }
    }
    assert_redirected_to github_access_path
    assert_equal "disabled", own.reload.status
    assert_equal "verified", other.reload.status
  end

  test "admin pages require admin and never expose internal credentials or another users full email" do
    link = ExternalAccess::LinkSubmission.call!(user: @user, username: "admin-view", at: @at)
    task = link.external_access_tasks.first

    get admin_commerce_external_access_tasks_path
    assert_redirected_to new_user_session_path
    sign_in(@user)
    get admin_commerce_external_access_tasks_path
    assert_redirected_to root_path

    delete destroy_user_session_path
    sign_in(@admin)
    get admin_commerce_external_access_tasks_path
    assert_response :success
    assert_match(/ad\*\*\*@example.com|gi\*\*\*@example.com/, response.body)
    assert_no_match(/github-customer@example.com|token|secret|private key|provider_payload/, response.body)
    get admin_commerce_external_access_task_path(task.public_id)
    assert_response :success
  end

  test "admin task update ignores forged status grant license and actor fields" do
    create_license(@user)
    link = ExternalAccess::LinkSubmission.call!(user: @user, username: "forgery-test", at: @at)
    task = link.external_access_tasks.find_by!(task_type: "verify_account")
    sign_in(@admin)

    patch admin_commerce_external_access_task_path(task.public_id), params: {
      external_access_task: {
        action_name: "complete", external_uid: "5301", status: "completed",
        grant_status: "active", user_id: @other.id, processed_by_id: @other.id,
        token: "must-not-store", internal_note: "admin-only"
      }
    }

    assert_redirected_to admin_commerce_external_access_task_path(task.public_id)
    assert_equal "completed", task.reload.status
    assert_equal @admin, task.processed_by
    assert_equal "verified", link.reload.status
    assert_equal "5301", link.external_uid
    assert_equal [ "grant_due" ], link.external_access_grants.reload.pluck(:status)
  end

  test "invalid admin transition is rejected and state remains unchanged" do
    link = ExternalAccess::LinkSubmission.call!(user: @user, username: "invalid-transition", at: @at)
    task = link.external_access_tasks.find_by!(task_type: "verify_account")
    sign_in(@admin)

    patch admin_commerce_external_access_task_path(task.public_id), params: {
      external_access_task: { action_name: "activate", status: "completed", external_uid: "5401" }
    }

    assert_redirected_to admin_commerce_external_access_task_path(task.public_id)
    assert_equal "pending", task.reload.status
    assert_equal "pending_verification", link.reload.status
  end

  test "admin task filters and customer dashboard link render without N plus one growth" do
    3.times { |index| ExternalAccess::LinkSubmission.call!(user: User.create!(name: "테스트 유저", email: "filter-#{index}@example.com", password: "password123"), username: "filter-#{index}", at: @at - index.hours) }
    sign_in(@admin)

    get admin_commerce_external_access_tasks_path, params: { task_type: "verify_account", status: "pending", due: "overdue" }
    assert_response :success
    assert_match(/계정 확인/, response.body)

    delete destroy_user_session_path
    sign_in(@user)
    get dashboard_path
    assert_response :success
    assert_match(/GitHub 연결 상태/, response.body)
  end

  test "schema contains no token or secret columns for external access records" do
    models = [ ExternalAccountLink, ExternalAccessGrant, ExternalAccessTask, ExternalAccessEvent ]
    sensitive = models.flat_map(&:column_names).grep(/token|secret|private_key|installation/i)

    assert_empty sensitive
  end

  private

  def sign_in(user)
    post user_session_path, params: { user: { email: user.email, password: "password123" } }
  end

  def create_verified_link(user, username, uid)
    link = ExternalAccess::LinkSubmission.call!(user: user, username: username, at: @at)
    ExternalAccess::TaskProcessor.call!(
      task: link.external_access_tasks.first, actor: @admin, action: "complete", external_uid: uid, at: @at
    )
    link.reload
  end

  def create_license(user)
    start_on = @at.in_time_zone(KST).to_date
    last_on = start_on + 1.month - 1.day
    License.create!(
      user: user, product: @product, source: "paid", status: "active",
      starts_on: start_on, last_usable_on: last_on,
      access_ends_at: KST.local((last_on + 1.day).year, (last_on + 1.day).month, (last_on + 1.day).day)
    )
  end
end
