require "test_helper"

class CommerceReconciliationTest < ActiveSupport::TestCase
  KST = Commerce::PeriodCalculator::KST

  setup do
    Commerce::CatalogBootstrap.call!
    @previous_flag = ENV["LEEDOX_COMMERCE_ENABLED"]
    ENV["LEEDOX_COMMERCE_ENABLED"] = "true"
    @product = Product.find_by!(code: "chatdox")
    @product.update!(sale_enabled: true)
    @offer = @product.product_offers.find_by!(code: "chatdox-1m-v1")
    @at = Time.current.change(usec: 0)
    @sequence = 0
  end

  teardown do
    @previous_flag.nil? ? ENV.delete("LEEDOX_COMMERCE_ENABLED") : ENV["LEEDOX_COMMERCE_ENABLED"] = @previous_flag
  end

  test "normal finalized order has no reconciliation issue and the scan is read only" do
    order = create_order
    Commerce::OrderFinalizer.call!(order: order, payment: payment_for(order), at: @at)
    before = database_snapshot

    report = Commerce::Reconciliation.call(at: @at + 1.minute, log: false)

    assert report.ok?
    assert_empty report.issues
    assert_equal before, database_snapshot
  end

  test "reconciliation detects every required anomaly without changing data" do
    paid_without_transaction = finalized_order
    paid_without_transaction.payment_transaction.destroy!

    paid_without_license = finalized_order
    License.where(order_item_id: paid_without_license.order_item_ids).delete_all

    create_order(at: @at - 2.hours)

    terminal_with_license = finalized_order
    terminal_with_license.update_columns(status: "failed")

    amount_mismatch = create_order
    amount_mismatch.payment_transaction.update_column(:amount, 1)

    item_mismatch = create_order
    item_mismatch.order_items.first.update_column(:total_amount, 1)

    create_overlapping_licenses

    transaction_with_subscription = create_order
    subscription = transaction_with_subscription.user.create_subscription!(
      provider: "toss",
      provider_customer_id: "test-reconciliation-customer",
      status: "active"
    )
    transaction_with_subscription.payment_transaction.update!(subscription: subscription)

    processed_unfinalized = create_order
    processed_unfinalized.payment_transaction.update!(
      status: "active",
      provider_payment_id: "processed-#{processed_unfinalized.public_id}",
      provider_payload: { "status" => "DONE" }
    )

    before = database_snapshot
    report = Commerce::Reconciliation.call(stale_after: 30.minutes, at: @at, log: false)
    codes = report.issues.map(&:code)

    %w[
      paid_without_transaction paid_without_license stale_pending
      terminal_order_with_license payment_amount_mismatch
      order_item_total_mismatch overlapping_license
      purchase_transaction_with_subscription processed_payment_unfinalized
    ].each { |code| assert_includes codes, code }
    assert_not report.ok?
    assert_equal before, database_snapshot
    assert report.issues.all? { |issue| issue.order_public_id.present? }
  end

  private

  def create_order(at: @at)
    @sequence += 1
    user = User.create!(
      email: "reconciliation-#{@sequence}@example.com",
      password: "password123",
      created_at: 30.days.ago
    )
    Commerce::OrderCreator.call!(
      user: user,
      product_code: "chatdox",
      offer_code: @offer.code,
      requested_start_on: at.in_time_zone(KST).to_date,
      provider: "toss",
      at: at
    )
  end

  def finalized_order
    order = create_order
    Commerce::OrderFinalizer.call!(order: order, payment: payment_for(order), at: @at)
  end

  def payment_for(order)
    {
      provider: order.provider,
      provider_payment_id: "reconciliation-payment-#{order.public_id}",
      order_id: order.public_id,
      amount: order.total_amount,
      currency: order.currency,
      provider_payload: { "status" => "DONE" }
    }
  end

  def create_overlapping_licenses
    user = User.create!(email: "overlap@example.com", password: "password123", created_at: 30.days.ago)
    first_start = @at.in_time_zone(KST).to_date
    [ first_start, first_start + 1.day ].each do |start_on|
      last_on = start_on + 1.month - 1.day
      License.create!(
        user: user,
        product: @product,
        source: "paid",
        status: "active",
        starts_on: start_on,
        last_usable_on: last_on,
        access_ends_at: KST.local((last_on + 1.day).year, (last_on + 1.day).month, (last_on + 1.day).day)
      )
    end
  end

  def database_snapshot
    [ Order, OrderItem, PaymentTransaction, License, Subscription ].to_h do |model|
      [ model.name, [ model.count, model.order(:id).pluck(:id, :updated_at) ] ]
    end
  end
end
