require "net/http"
require "json"

module Portone
  class Client
    class Error < StandardError; end
    class TransportError < Error; end
    class ApiError < Error; end

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

      unless response.is_a?(Net::HTTPSuccess)
        error = parse_json(response.body)
        message = api_error_message(error, response)
        raise ApiError, "PortOne API error: #{message}"
      end

      JSON.parse(response.body)
    rescue Timeout::Error,
           Errno::ECONNREFUSED,
           SocketError,
           Net::OpenTimeout,
           Net::ReadTimeout => e
      raise TransportError.new("PortOne network error: #{e.message}"), cause: e
    end

    def self.parse_json(body)
      JSON.parse(body)
    rescue JSON::ParserError
      nil
    end

    def self.api_error_message(error, response)
      if error.is_a?(Hash)
        error["message"].presence || error["type"].presence || response.body.presence || response.code
      else
        response.body.presence || response.code
      end
    end
  end
end
