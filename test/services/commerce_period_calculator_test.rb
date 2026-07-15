require "test_helper"

class CommercePeriodCalculatorTest < ActiveSupport::TestCase
  KST = Commerce::PeriodCalculator::KST

  setup do
    Commerce::CatalogBootstrap.call!
    @user = User.create!(email: "period@example.com", password: "password123", created_at: 30.days.ago)
    @chatdox = Product.find_by!(code: "chatdox")
    @claudox = Product.find_by!(code: "claudox")
  end

  test "KST purchase date through plus seven is accepted and outside dates are rejected" do
    purchased_at = KST.local(2028, 1, 31, 23, 50)

    assert_equal Date.new(2028, 1, 31), Commerce::PeriodCalculator.validate_start!(
      start_on: Date.new(2028, 1, 31), purchased_at: purchased_at
    )
    assert_equal Date.new(2028, 2, 7), Commerce::PeriodCalculator.validate_start!(
      start_on: Date.new(2028, 2, 7), purchased_at: purchased_at
    )
    assert_raises(ArgumentError) do
      Commerce::PeriodCalculator.validate_start!(start_on: Date.new(2028, 1, 30), purchased_at: purchased_at)
    end
    assert_raises(ArgumentError) do
      Commerce::PeriodCalculator.validate_start!(start_on: Date.new(2028, 2, 8), purchased_at: purchased_at)
    end
  end

  test "normal month end leap year and February 29 anniversary follow policy" do
    assert_period "2027-05-15", 1, "2027-06-14", "2027-06-15"
    assert_period "2027-01-31", 1, "2027-02-28", "2027-03-01"
    assert_period "2028-01-31", 1, "2028-02-29", "2028-03-01"
    assert_period "2028-02-29", 12, "2029-02-28", "2029-03-01"
  end

  test "all offered durations use anniversary minus one day" do
    { 1 => "2027-06-14", 3 => "2027-08-14", 6 => "2027-11-14", 12 => "2028-05-14" }.each do |months, last_day|
      assert_period "2027-05-15", months, last_day, (Date.iso8601(last_day) + 1.day).iso8601
    end
  end

  test "active and scheduled licenses extend contiguously per product only" do
    at = KST.local(2027, 5, 15, 12)
    create_manual_license(@chatdox, "2027-05-15", "2027-06-14", "active")
    create_manual_license(@chatdox, "2027-06-15", "2027-07-14", "scheduled")
    create_manual_license(@claudox, "2027-10-01", "2027-10-31", "scheduled")

    result = Commerce::LicenseScheduler.preview(
      user: @user,
      product: @chatdox,
      duration_months: 3,
      requested_start_on: Date.new(2027, 5, 20),
      at: at
    )

    assert_equal Date.new(2027, 7, 15), result.starts_on
    assert_equal Date.new(2027, 10, 14), result.last_usable_on
  end

  private

  def assert_period(start_on, duration_months, last_usable_on, access_end_on)
    result = Commerce::PeriodCalculator.call(start_on: Date.iso8601(start_on), duration_months: duration_months)
    assert_equal Date.iso8601(last_usable_on), result.last_usable_on
    assert_equal KST.local(*Date.iso8601(access_end_on).then { |date| [ date.year, date.month, date.day ] }), result.access_ends_at
  end

  def create_manual_license(product, starts_on, last_usable_on, status)
    end_date = Date.iso8601(last_usable_on) + 1.day
    License.create!(
      user: @user,
      product: product,
      source: "paid",
      status: status,
      starts_on: Date.iso8601(starts_on),
      last_usable_on: Date.iso8601(last_usable_on),
      access_ends_at: KST.local(end_date.year, end_date.month, end_date.day)
    )
  end
end
