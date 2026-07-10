require "net/http"
require "json"

module Portone
  class Client
    BASE_URL = "https://api.portone.io"

    def self.get_payment(payment_id)
      get_json("/payments/#{URI.encode_www_form_component(payment_id)}")
    end

    def self.get_json(path)
      uri = URI("#{BASE_URL}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 60
      http.open_timeout = 10

      request = Net::HTTP::Get.new(uri.request_uri)
      request["Authorization"] = "PortOne #{ENV.fetch('PORTONE_API_SECRET')}"
      request["Content-Type"] = "application/json"

      response = http.request(request)
      result = JSON.parse(response.body)

      unless response.is_a?(Net::HTTPSuccess)
        raise "PortOne API error: #{result['message'] || result['type'] || response.code}"
      end

      result
    end
  end
end
