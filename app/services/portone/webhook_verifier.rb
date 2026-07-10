require "base64"
require "openssl"

module Portone
  class WebhookVerifier
    class VerificationError < StandardError; end

    def self.verify!(secret:, payload:, headers:)
      new(secret: secret, payload: payload, headers: headers).verify!
    end

    def initialize(secret:, payload:, headers:)
      @secret = secret
      @payload = payload
      @headers = headers
    end

    def verify!
      raise VerificationError, "missing webhook secret" if @secret.blank?
      raise VerificationError, "missing webhook headers" if webhook_id.blank? || timestamp.blank? || signature.blank?

      expected = Base64.strict_encode64(
        OpenSSL::HMAC.digest("SHA256", decoded_secret, "#{webhook_id}.#{timestamp}.#{@payload}")
      )

      return true if signature_values.any? { |value| secure_compare(value, expected) }

      raise VerificationError, "invalid webhook signature"
    end

    private

    def webhook_id
      header("webhook-id")
    end

    def timestamp
      header("webhook-timestamp")
    end

    def signature
      header("webhook-signature")
    end

    def header(name)
      @headers[name] || @headers[name.upcase.tr("-", "_")] || @headers["HTTP_#{name.upcase.tr('-', '_')}"]
    end

    def decoded_secret
      Base64.strict_decode64(@secret.to_s.delete_prefix("whsec_"))
    rescue ArgumentError
      raise VerificationError, "invalid webhook secret"
    end

    def signature_values
      signature.to_s.split(" ").filter_map do |entry|
        version, value = entry.split(",", 2)
        value if version == "v1"
      end
    end

    def secure_compare(left, right)
      ActiveSupport::SecurityUtils.secure_compare(left, right)
    rescue ArgumentError
      false
    end
  end
end
