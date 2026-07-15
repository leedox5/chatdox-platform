require "test_helper"

class CommerceReleasePreflightTest < ActiveSupport::TestCase
  setup do
    Commerce::CatalogBootstrap.call!
    @previous_flag = ENV["LEEDOX_COMMERCE_ENABLED"]
    @previous_toss_env = %w[TOSS_CLIENT_KEY TOSS_SECRET_KEY TOSS_WEBHOOK_SECRET].to_h { |key| [ key, ENV[key] ] }
    ENV["LEEDOX_COMMERCE_ENABLED"] = "false"
    @previous_toss_env.each_key { |key| ENV.delete(key) }
    Product.update_all(sale_enabled: false)
  end

  teardown do
    @previous_flag.nil? ? ENV.delete("LEEDOX_COMMERCE_ENABLED") : ENV["LEEDOX_COMMERCE_ENABLED"] = @previous_flag
    @previous_toss_env.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  test "preflight confirms closed gates and blocks only missing provider credential" do
    report = Commerce::ReleasePreflight.call(provider: "toss")
    statuses = report.checks.index_by(&:name)

    assert_equal "passed", statuses.fetch("global_sale_gate").status
    assert_equal "passed", statuses.fetch("chatdox_sale_gate").status
    assert_equal "passed", statuses.fetch("claudox_sale_gate").status
    assert_equal "passed", statuses.fetch("catalog_products").status
    assert_equal "passed", statuses.fetch("chatdox_offers").status
    assert_equal "passed", statuses.fetch("callback_routes").status
    assert_equal "blocked", statuses.fetch("provider_configuration").status
    assert_not report.ready_for_sandbox?
  end

  test "sales service requires every combination of global and product gates" do
    product = Product.find_by!(code: "chatdox")

    [ false, true ].product([ false, true ]).each do |global, product_enabled|
      ENV["LEEDOX_COMMERCE_ENABLED"] = global.to_s
      product.update!(sale_enabled: product_enabled)
      assert_equal global && product_enabled, Commerce::Sales.enabled_for?(product)
    end
  end
end
