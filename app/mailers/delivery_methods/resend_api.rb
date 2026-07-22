require "net/http"
require "json"

module DeliveryMethods
  # Sends mail through Resend's HTTP API (https://api.resend.com/emails) instead of
  # SMTP. Railway blocks outbound SMTP ports (587/465) but allows HTTPS (443), so the
  # SMTP relay approach can't connect at all -- this bypasses that entirely.
  class ResendApi
    ENDPOINT = URI("https://api.resend.com/emails")

    attr_accessor :settings

    def initialize(settings)
      self.settings = settings
    end

    def deliver!(mail)
      response = perform_request(build_request(mail))
      raise "Resend API delivery failed: #{response.code} #{response.body}" unless success?(response)

      response
    end

    private

    def build_request(mail)
      request = Net::HTTP::Post.new(ENDPOINT)
      request["Authorization"] = "Bearer #{settings.fetch(:api_key)}"
      request["Content-Type"] = "application/json"
      request.body = payload_for(mail).to_json
      request
    end

    def payload_for(mail)
      payload = {
        from: mail[:from].formatted.first,
        to: mail[:to].formatted,
        subject: mail.subject
      }
      payload[:cc] = mail[:cc].formatted if mail[:cc].present?
      payload[:bcc] = mail[:bcc].formatted if mail[:bcc].present?
      payload[:reply_to] = mail[:reply_to].formatted if mail[:reply_to].present?
      payload.merge!(body_parts_for(mail))
      payload
    end

    def body_parts_for(mail)
      if mail.multipart?
        { html: mail.html_part&.body&.decoded, text: mail.text_part&.body&.decoded }.compact
      elsif mail.content_type.to_s.include?("html")
        { html: mail.body.decoded }
      else
        { text: mail.body.decoded }
      end
    end

    def perform_request(request)
      Net::HTTP.start(ENDPOINT.hostname, ENDPOINT.port, **connection_options) { |http| http.request(request) }
    end

    def connection_options
      {
        use_ssl: true,
        open_timeout: settings.fetch(:open_timeout, 5),
        read_timeout: settings.fetch(:read_timeout, 10)
      }
    end

    def success?(response)
      response.code.to_i.between?(200, 299)
    end
  end
end
