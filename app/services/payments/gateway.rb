module Payments
  class Gateway
    PROVIDERS = %w[toss portone].freeze

    def self.current
      provider = ENV.fetch("PAYMENT_PROVIDER")
      raise KeyError, "runtime payment provider must be portone" unless provider == "portone"

      self.for(provider)
    end

    def self.for(provider)
      {
        "toss" => TossGateway,
        "portone" => PortoneGateway
      }.fetch(provider).new
    end
  end
end
