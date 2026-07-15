require "test_helper"

class CommerceReleasePreflightTest < ActiveSupport::TestCase
  setup do
    Commerce::CatalogBootstrap.call!
    @previous_flag = ENV["LEEDOX_COMMERCE_ENABLED"]
    @payment_keys = %w[
      PAYMENT_PROVIDER TOSS_CLIENT_KEY TOSS_SECRET_KEY TOSS_WEBHOOK_SECRET
      PORTONE_API_SECRET PORTONE_STORE_ID PORTONE_CHANNEL_KEY PORTONE_WEBHOOK_SECRET
    ]
    @previous_payment_env = @payment_keys.to_h { |key| [ key, ENV[key] ] }
    ENV["LEEDOX_COMMERCE_ENABLED"] = "false"
    @payment_keys.each { |key| ENV.delete(key) }
    Product.update_all(sale_enabled: false)
  end

  teardown do
    @previous_flag.nil? ? ENV.delete("LEEDOX_COMMERCE_ENABLED") : ENV["LEEDOX_COMMERCE_ENABLED"] = @previous_flag
    @previous_payment_env.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  test "preflight confirms closed gates and blocks missing runtime and credentials" do
    report = Commerce::ReleasePreflight.call(provider: "portone")
    statuses = report.checks.index_by(&:name)

    assert_equal "passed", statuses.fetch("global_sale_gate").status
    assert_equal "passed", statuses.fetch("chatdox_sale_gate").status
    assert_equal "passed", statuses.fetch("claudox_sale_gate").status
    assert_equal "passed", statuses.fetch("catalog_products").status
    assert_equal "passed", statuses.fetch("chatdox_offers").status
    assert_equal "passed", statuses.fetch("callback_routes").status
    assert_equal "failed", statuses.fetch("runtime_provider").status
    assert_equal "blocked", statuses.fetch("provider_configuration").status
    assert_not report.ready_for_sandbox?
  end

  test "preflight passes only when requested and runtime providers are explicit portone" do
    configure_portone

    report = Commerce::ReleasePreflight.call(provider: "portone")
    statuses = report.checks.index_by(&:name)

    assert_equal "passed", statuses.fetch("runtime_provider").status
    assert_equal "passed", statuses.fetch("provider_configuration").status
    assert report.ready_for_sandbox?
  end

  test "preflight rejects provider mismatch toss unknown case and whitespace" do
    configure_portone

    [ "toss", "PortOne", " portone ", "unknown", "" ].each do |requested|
      report = Commerce::ReleasePreflight.call(provider: requested)

      assert_equal "failed", report.checks.index_by(&:name).fetch("runtime_provider").status
      assert_not report.ready_for_sandbox?
    end

    ENV["PAYMENT_PROVIDER"] = "toss"
    report = Commerce::ReleasePreflight.call(provider: "portone")
    assert_equal "failed", report.checks.index_by(&:name).fetch("runtime_provider").status
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


  private

  def configure_portone
    ENV.update(
      "PAYMENT_PROVIDER" => "portone",
      "PORTONE_API_SECRET" => "test-api",
      "PORTONE_STORE_ID" => "test-store",
      "PORTONE_CHANNEL_KEY" => "test-channel",
      "PORTONE_WEBHOOK_SECRET" => "test-webhook"
    )
  end
end
