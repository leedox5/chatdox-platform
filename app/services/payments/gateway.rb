module Payments
  class Gateway
    # "manual" (Order::MANUAL_PROVIDER) is included here because this list also
    # doubles as the Order/PaymentTransaction#provider allowlist -- it is NOT a
    # gateway this class can resolve. `for` deliberately has no "manual" entry,
    # so a manual-provider order accidentally routed through Payments::Gateway
    # fails loudly instead of silently doing nothing.
    PROVIDERS = %w[portone manual].freeze

    def self.current
      provider = ENV.fetch("PAYMENT_PROVIDER")
      raise KeyError, "runtime payment provider must be portone" unless provider == "portone"

      self.for(provider)
    end

    def self.for(provider)
      { "portone" => PortoneGateway }.fetch(provider).new
    end
  end
end
