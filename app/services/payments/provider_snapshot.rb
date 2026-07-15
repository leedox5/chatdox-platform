module Payments
  class ProviderSnapshot
    ALLOWED_KEYS = %w[status].freeze

    def self.build(provider:, payload:)
      raise ArgumentError, "unsupported payment provider" unless Payments::Gateway::PROVIDERS.include?(provider.to_s)

      source = payload.to_h.stringify_keys
      source.slice(*ALLOWED_KEYS).compact_blank
    end
  end
end
