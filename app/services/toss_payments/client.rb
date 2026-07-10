require "net/http"
require "json"
require "base64"

module TossPayments
  class Client
    BASE_URL = "https://api.tosspayments.com"

    def self.post_json(path, body)
      secret_key = ENV.fetch("TOSS_SECRET_KEY")
      encoded = Base64.strict_encode64("#{secret_key}:")

      uri = URI("#{BASE_URL}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.path)
      request["Authorization"] = "Basic #{encoded}"
      request["Content-Type"] = "application/json"
      request.body = body.to_json

      response = http.request(request)
      result = JSON.parse(response.body)

      unless response.is_a?(Net::HTTPSuccess)
        raise "TossPayments API error: #{result['message']} (code: #{result['code']})"
      end

      result
    end

    def self.get_json(path)
      secret_key = ENV.fetch("TOSS_SECRET_KEY")
      encoded = Base64.strict_encode64("#{secret_key}:")

      uri = URI("#{BASE_URL}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.path)
      request["Authorization"] = "Basic #{encoded}"

      response = http.request(request)
      result = JSON.parse(response.body)

      unless response.is_a?(Net::HTTPSuccess)
        raise "TossPayments API error: #{result['message']} (code: #{result['code']})"
      end

      result
    end
  end
end
