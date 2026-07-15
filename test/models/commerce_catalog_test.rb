require "test_helper"

class CommerceCatalogTest < ActiveSupport::TestCase
  setup do
    Commerce::CatalogBootstrap.call!
  end

  test "catalog separates products and installs exact Chatdox offers only" do
    chatdox = Product.find_by!(code: "chatdox")
    claudox = Product.find_by!(code: "claudox")

    assert_equal [ "chatdox", "claudox" ], Product.order(:code).pluck(:code)
    assert_equal false, claudox.sale_enabled?
    assert_empty claudox.product_offers
    assert_equal [
      [ "chatdox-1m-v1", 1, 7_000, 700, 7_700, 0 ],
      [ "chatdox-3m-v1", 3, 21_000, 2_100, 23_100, 0 ],
      [ "chatdox-6m-v1", 6, 37_800, 3_780, 41_580, 1_000 ],
      [ "chatdox-12m-v1", 12, 67_200, 6_720, 73_920, 2_000 ]
    ], chatdox.product_offers.ordered.pluck(
      :code, :duration_months, :supply_amount, :vat_amount, :total_amount, :discount_bps
    )
  end

  test "catalog bootstrap is idempotent and does not overwrite operator changes" do
    offer = ProductOffer.find_by!(code: "chatdox-1m-v1")
    offer.update!(active: false)

    assert_no_difference [ "Product.count", "ProductOffer.count" ] do
      2.times { Commerce::CatalogBootstrap.call! }
    end

    assert_not offer.reload.active?
  end

  test "catalog database and model constraints reject duplicates and invalid totals" do
    chatdox = Product.find_by!(code: "chatdox")
    duplicate = Product.new(code: chatdox.code, name: "Duplicate")
    assert_not duplicate.valid?

    offer = ProductOffer.new(
      product: chatdox,
      code: "invalid-total",
      version: 2,
      duration_months: 1,
      supply_amount: 100,
      vat_amount: 10,
      total_amount: 999,
      discount_bps: 0,
      currency: "KRW"
    )
    assert_not offer.valid?
    assert_includes offer.errors[:total_amount], "must equal supply amount plus VAT"

    user = User.create!(name: "테스트 유저", email: "legacy-transaction@example.com", password: "password123")
    subscription = user.create_subscription!(
      provider: "toss",
      provider_customer_id: "legacy-customer",
      status: "active"
    )
    transaction = subscription.payment_transactions.create!(
      provider: "toss",
      provider_payment_id: "legacy-payment",
      order_id: "legacy-order",
      status: "active",
      amount: 9_900,
      currency: "KRW",
      provider_payload: {}
    )
    assert_equal subscription, transaction.subscription
    assert_nil transaction.purchase_order
  end
end
