module Payments
  class Gateway
    PROVIDERS = %w[toss portone].freeze

    def self.current
      self.for(ENV.fetch("PAYMENT_PROVIDER", "toss"))
    end

    def self.for(provider)
      {
        "toss" => TossGateway,
        "portone" => PortoneGateway
      }.fetch(provider).new
    end
  end
end
