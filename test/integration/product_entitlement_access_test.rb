require "test_helper"

class ProductEntitlementAccessTest < ActionDispatch::IntegrationTest
  setup do
    Commerce::CatalogBootstrap.call!
    @user = User.create!(email: "reader@example.com", password: "password123", created_at: 30.days.ago)
    post user_session_path, params: { user: { email: @user.email, password: "password123" } }
  end

  test "Claudox index cannot use id parameter to bypass paid chapter policy" do
    get claudox_read_path, params: { id: "06" }

    assert_redirected_to root_path
    assert_equal "이 작업을 할 권한이 없습니다.", flash[:alert]
  end

  test "product license opens only its matching controller" do
    product = Product.find_by!(code: "chatdox")
    today = Time.current.in_time_zone(Commerce::PeriodCalculator::KST).to_date
    end_date = today + 1.month
    License.create!(
      user: @user,
      product: product,
      source: "paid",
      status: "active",
      starts_on: today,
      last_usable_on: end_date - 1.day,
      access_ends_at: Commerce::PeriodCalculator::KST.local(end_date.year, end_date.month, end_date.day)
    )

    get doc_path("06")
    assert_response :success

    get claudox_chapter_path("06")
    assert_redirected_to root_path
  end
end
