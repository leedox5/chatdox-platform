require "test_helper"

class ProductEntitlementTest < ActiveSupport::TestCase
  KST = Commerce::PeriodCalculator::KST

  setup do
    Commerce::CatalogBootstrap.call!
    @previous_legacy_access = ENV.delete("LEEDOX_LEGACY_CHATDOX_ACCESS")
    @at = Time.current
    @user = User.create!(name: "테스트 유저", email: "entitled@example.com", password: "password123", created_at: 30.days.ago)
    @other_user = User.create!(name: "테스트 유저", email: "other@example.com", password: "password123", created_at: 30.days.ago)
    @chatdox = Product.find_by!(code: "chatdox")
    @claudox = Product.find_by!(code: "claudox")
  end

  teardown do
    if @previous_legacy_access.nil?
      ENV.delete("LEEDOX_LEGACY_CHATDOX_ACCESS")
    else
      ENV["LEEDOX_LEGACY_CHATDOX_ACCESS"] = @previous_legacy_access
    end
  end

  test "Chatdox and Claudox paid access are isolated by product" do
    today = @at.in_time_zone(KST).to_date
    create_license(@user, @chatdox, starts_on: today, last_on: today + 1.month - 1.day)

    assert DocPolicy.new(@user, chapter("chatdox", 6)).view?
    assert_not DocPolicy.new(@user, chapter("claudox", 6)).view?

    create_license(@other_user, @claudox, starts_on: today, last_on: today + 1.month - 1.day)
    assert DocPolicy.new(@other_user, chapter("claudox", 6)).view?
    assert_not DocPolicy.new(@other_user, chapter("chatdox", 6)).view?
  end

  test "license permits access before exact KST end and blocks at and after it" do
    license = create_license(@user, @chatdox, starts_on: "2027-05-01", last_on: "2027-05-31")

    assert license.active_at?(KST.local(2027, 5, 31, 23, 59, 59))
    assert_not license.active_at?(KST.local(2027, 6, 1, 0, 0, 0))
    assert_not license.active_at?(KST.local(2027, 6, 2, 0, 0, 0))
  end

  test "scheduled license and another users license do not grant access" do
    today = @at.in_time_zone(KST).to_date
    create_license(@other_user, @chatdox, starts_on: today + 5.days, last_on: today + 1.month + 4.days, status: "scheduled")

    assert_not Entitlements::ProductAccess.allowed?(user: @other_user, product_code: "chatdox", at: @at)
    assert_not Entitlements::ProductAccess.allowed?(user: @user, product_code: "chatdox", at: @at + 10.days)
  end

  test "guest and trial chapter ranges remain two and five" do
    trial_user = User.create!(name: "테스트 유저", email: "trial@example.com", password: "password123")

    assert DocPolicy.new(nil, chapter("chatdox", 2)).view?
    assert_not DocPolicy.new(nil, chapter("chatdox", 3)).view?
    assert DocPolicy.new(trial_user, chapter("chatdox", 5)).view?
    assert_not DocPolicy.new(trial_user, chapter("chatdox", 6)).view?
  end

  test "legacy subscription access requires an explicit true gate and never unlocks Claudox" do
    @user.create_subscription!(
      provider: "toss",
      provider_customer_id: "legacy-user",
      status: "active",
      active: true,
      current_period_start: 1.day.ago,
      current_period_end: 1.month.from_now
    )

    assert_not Entitlements::ProductAccess.allowed?(user: @user, product_code: "chatdox")

    ENV["LEEDOX_LEGACY_CHATDOX_ACCESS"] = "false"
    assert_not Entitlements::ProductAccess.allowed?(user: @user, product_code: "chatdox")

    ENV["LEEDOX_LEGACY_CHATDOX_ACCESS"] = "true"
    assert Entitlements::ProductAccess.allowed?(user: @user, product_code: "chatdox")
    assert_not Entitlements::ProductAccess.allowed?(user: @user, product_code: "claudox")
  end

  private

  def chapter(product_code, number)
    { id: number.to_s.rjust(2, "0"), product_code: product_code }
  end

  def create_license(user, product, starts_on:, last_on:, status: "active")
    last_date = last_on.to_date
    end_date = last_date + 1.day
    License.create!(
      user: user,
      product: product,
      source: "paid",
      status: status,
      starts_on: starts_on.to_date,
      last_usable_on: last_date,
      access_ends_at: KST.local(end_date.year, end_date.month, end_date.day)
    )
  end
end
