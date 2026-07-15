require "test_helper"

class CommerceOrderFlowTest < ActiveSupport::TestCase
  KST = Commerce::PeriodCalculator::KST

  setup do
    Commerce::CatalogBootstrap.call!
    @previous_flag = ENV["LEEDOX_COMMERCE_ENABLED"]
    ENV["LEEDOX_COMMERCE_ENABLED"] = "true"
    @user = User.create!(email: "buyer@example.com", password: "password123", created_at: 30.days.ago)
    @product = Product.find_by!(code: "chatdox")
    @product.update!(sale_enabled: true)
    @offer = @product.product_offers.find_by!(code: "chatdox-1m-v1")
    @at = KST.local(2027, 5, 15, 12)
  end

  teardown do
    @previous_flag.nil? ? ENV.delete("LEEDOX_COMMERCE_ENABLED") : ENV["LEEDOX_COMMERCE_ENABLED"] = @previous_flag
  end

  test "pending order snapshots catalog values and creates no subscription" do
    assert_difference [ "Order.count", "OrderItem.count", "PaymentTransaction.count" ], 1 do
      assert_no_difference "Subscription.count" do
        @order = create_order
      end
    end

    assert_equal "pending", @order.status
    assert_equal [ 7_000, 700, 7_700, "KRW" ], [
      @order.supply_amount, @order.vat_amount, @order.total_amount, @order.currency
    ]
    assert_equal [ "chatdox", "chatdox-1m-v1", 1, 7_000, 700, 7_700, 0 ],
      @order.order_items.pluck(
        :product_code, :offer_code, :duration_months, :supply_amount,
        :vat_amount, :total_amount, :discount_bps
      ).first
    assert_nil @order.payment_transaction.subscription_id
  end

  test "order and item snapshots remain unchanged when catalog changes and reject direct edits" do
    order = create_order
    item = order.order_items.first!
    @offer.update!(supply_amount: 8_000, vat_amount: 800, total_amount: 8_800)

    assert_equal 7_700, order.reload.total_amount
    assert_equal 7_700, item.reload.total_amount
    assert_not order.update(total_amount: 1)
    assert_not item.update(product_name: "Changed")
  end

  test "inactive expired and cross-product offers are rejected" do
    @offer.update!(active: false)
    assert_raises(Commerce::OrderCreator::Unavailable) { create_order }

    @offer.update!(active: true, available_until: @at - 1.second)
    assert_raises(Commerce::OrderCreator::Unavailable) { create_order }

    assert_raises(Commerce::OrderCreator::Unavailable) do
      Commerce::OrderCreator.call!(
        user: @user,
        product_code: "claudox",
        offer_code: @offer.code,
        requested_start_on: @at.to_date,
        provider: "toss",
        at: @at
      )
    end
  end

  test "server verification rejects provider order amount and currency mismatches" do
    %w[toss portone].each do |provider|
      order = create_order(provider: provider)
      {
        provider: provider == "toss" ? "portone" : "toss",
        order_id: "another-order",
        amount: 1,
        currency: "USD"
      }.each do |field, bad_value|
        bad_payment = payment_for(order, provider: provider).merge(field => bad_value)

        assert_raises(Commerce::OrderFinalizer::VerificationError) do
          Commerce::OrderFinalizer.call!(order: order, payment: bad_payment, at: @at)
        end
        assert_equal "pending", order.reload.status
        assert_empty order.licenses
      end
    end
  end

  test "approval is atomic and duplicate callback is idempotent without subscription" do
    order = create_order
    payment = payment_for(order)

    assert_difference "License.count", 1 do
      assert_no_difference [ "Order.count", "PaymentTransaction.count", "Subscription.count" ] do
        Commerce::OrderFinalizer.call!(order: order, payment: payment, at: @at)
      end
    end
    assert_no_difference [ "Order.count", "License.count", "PaymentTransaction.count", "Subscription.count" ] do
      Commerce::OrderFinalizer.call!(order: order.reload, payment: payment, at: @at + 1.minute)
    end

    assert_equal "paid", order.reload.status
    assert_equal "provider-payment-#{order.public_id}", order.payment_transaction.reload.provider_payment_id
    assert_raises(Commerce::OrderFinalizer::VerificationError) do
      Commerce::OrderFinalizer.call!(
        order: order,
        payment: payment.merge(provider_payment_id: "different-payment"),
        at: @at
      )
    end
  end

  test "two pending approvals for the same product produce contiguous nonoverlapping licenses" do
    first_order = create_order
    second_order = create_order

    Commerce::OrderFinalizer.call!(order: first_order, payment: payment_for(first_order), at: @at)
    Commerce::OrderFinalizer.call!(order: second_order, payment: payment_for(second_order), at: @at)

    licenses = @user.licenses.where(product: @product).order(:starts_on).to_a
    assert_equal 2, licenses.size
    assert_equal licenses.first.last_usable_on + 1.day, licenses.second.starts_on
  end

  test "failed payment creates no license" do
    order = create_order

    assert_no_difference "License.count" do
      Commerce::OrderStatusSync.call!(
        order: order,
        status: "failed",
        payment: payment_for(order),
        at: @at
      )
    end

    assert_equal "failed", order.reload.status
  end

  test "database failure rolls finalization back and the same payment safely recovers" do
    order = create_order
    payment = payment_for(order)
    failure = ->(**_arguments) { raise ActiveRecord::StatementInvalid, "simulated database failure" }

    with_singleton_method(Commerce::LicenseScheduler, :create_for!, failure) do
      assert_raises(ActiveRecord::StatementInvalid) do
        Commerce::OrderFinalizer.call!(order: order, payment: payment, at: @at)
      end
    end

    order.reload
    assert_equal "pending", order.status
    assert_equal "pending", order.payment_transaction.status
    assert_match(/\Apending:/, order.payment_transaction.provider_payment_id)
    assert_empty order.licenses
    assert_nil order.paid_at
    assert_nil order.finalized_at

    assert_difference "License.count", 1 do
      Commerce::OrderFinalizer.call!(order: order, payment: payment, at: @at + 1.minute)
    end
    assert_equal "paid", order.reload.status
    assert_equal 1, order.licenses.count
    assert_equal 1, PaymentTransaction.where(purchase_order: order).count
    assert_nil @user.reload.subscription
  end

  private

  def create_order(provider: "toss")
    Commerce::OrderCreator.call!(
      user: @user,
      product_code: "chatdox",
      offer_code: @offer.code,
      requested_start_on: @at.to_date,
      provider: provider,
      at: @at
    )
  end

  def payment_for(order, provider: order.provider)
    {
      provider: provider,
      provider_payment_id: "provider-payment-#{order.public_id}",
      order_id: order.public_id,
      amount: order.total_amount,
      currency: order.currency,
      provider_payload: { "status" => "DONE" }
    }
  end


  def with_singleton_method(object, method_name, replacement)
    original = object.method(method_name)
    object.define_singleton_method(method_name, replacement)
    yield
  ensure
    object.define_singleton_method(method_name, original)
  end
end
