module Payments
  class Configuration
    REQUIRED_KEYS = {
      "toss" => %w[TOSS_CLIENT_KEY TOSS_SECRET_KEY TOSS_WEBHOOK_SECRET],
      "portone" => %w[PORTONE_API_SECRET PORTONE_STORE_ID PORTONE_CHANNEL_KEY PORTONE_WEBHOOK_SECRET]
    }.freeze
    WEBHOOK_KEYS = {
      "toss" => %w[TOSS_SECRET_KEY TOSS_WEBHOOK_SECRET],
      "portone" => %w[PORTONE_API_SECRET PORTONE_WEBHOOK_SECRET]
    }.freeze

    attr_reader :provider

    def self.current
      new(provider: ENV.fetch("PAYMENT_PROVIDER", "toss"))
    end

    def initialize(provider:)
      @provider = provider.to_s
    end

    def ready?
      valid_provider? && missing_keys.empty?
    end

    def webhook_ready?
      valid_provider? && missing_webhook_keys.empty?
    end

    def valid_provider?
      Payments::Gateway::PROVIDERS.include?(provider)
    end

    def missing_keys
      return [ "PAYMENT_PROVIDER" ] unless valid_provider?

      REQUIRED_KEYS.fetch(provider).reject { |key| ENV[key].present? }
    end

    def missing_webhook_keys
      return [ "PAYMENT_PROVIDER" ] unless valid_provider?

      WEBHOOK_KEYS.fetch(provider).reject { |key| ENV[key].present? }
    end
  end
end
