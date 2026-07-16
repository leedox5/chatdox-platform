require "test_helper"

class PaymentsProviderSnapshotTest < ActiveSupport::TestCase
  SENSITIVE_PAYLOAD = {
    "status" => "PAID",
    "paymentMethod" => { "card" => { "number" => "sensitive-card" } },
    "customer" => {
      "name" => "sensitive-name",
      "email" => "sensitive@example.com",
      "phoneNumber" => "010-0000-0000",
      "address" => "sensitive-address"
    },
    "token" => "sensitive-token",
    "secret" => "sensitive-secret",
    "receiptUrl" => "https://sensitive.example/receipt",
    "redirectUrl" => "https://sensitive.example/redirect",
    "metadata" => { "future" => "sensitive-metadata" },
    "unknownFutureKey" => "sensitive-unknown"
  }.freeze

  test "explicit allowlist retains only provider status" do
    snapshot = Payments::ProviderSnapshot.build(provider: "portone", payload: SENSITIVE_PAYLOAD)

    assert_equal({ "status" => "PAID" }, snapshot)
    assert_equal Payments::ProviderSnapshot::ALLOWED_KEYS, snapshot.keys
  end

  test "unknown provider fails closed" do
    assert_raises(ArgumentError) do
      Payments::ProviderSnapshot.build(provider: " portone ", payload: SENSITIVE_PAYLOAD)
    end
  end

  test "payment and order identifiers are filtered from request logs" do
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    filtered = filter.filter(
      "paymentId" => "sensitive-payment-id",
      "paymentKey" => "sensitive-payment-key",
      "orderId" => "sensitive-order-id",
      "customerEmail" => "sensitive@example.com"
    )

    assert_equal [ "[FILTERED]" ], filtered.values.uniq
  end
end
