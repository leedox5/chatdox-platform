require "test_helper"

module DeliveryMethods
  class ResendApiTest < ActiveSupport::TestCase
    # Records the built Net::HTTP::Post instead of hitting the network, so payload
    # and header assertions can inspect exactly what would have been sent.
    class RecordingResendApi < DeliveryMethods::ResendApi
      attr_reader :last_request
      attr_writer :response_to_return

      private

      def perform_request(request)
        @last_request = request
        @response_to_return
      end
    end

    def ok_response(body = '{"id":"49a3999c-0ce1-4ea6-ab68-afcd6dc2e794"}')
      response = Net::HTTPOK.new("1.1", "200", "OK")
      response.define_singleton_method(:body) { body }
      response
    end

    def error_response(code, body)
      response = Net::HTTPResponse::CODE_TO_OBJ.fetch(code).new("1.1", code, "Error")
      response.define_singleton_method(:body) { body }
      response
    end

    def deliver(mail, response: ok_response, **settings)
      delivery = RecordingResendApi.new(api_key: "re_test_key", **settings)
      delivery.response_to_return = response
      delivery.deliver!(mail)
      delivery
    end

    test "posts the mail to the Resend API with the expected JSON payload" do
      mail = Mail.new do
        from "noreply@leedox.up.railway.app"
        to "user@example.com"
        subject "Reset your password"
        body "<p>Hi</p>"
        content_type "text/html; charset=UTF-8"
      end

      request = deliver(mail).last_request
      payload = JSON.parse(request.body)

      assert_equal "Bearer re_test_key", request["Authorization"]
      assert_equal "application/json", request["Content-Type"]
      assert_equal "noreply@leedox.up.railway.app", payload["from"]
      assert_equal [ "user@example.com" ], payload["to"]
      assert_equal "Reset your password", payload["subject"]
      assert_equal "<p>Hi</p>", payload["html"]
      assert_nil payload["text"]
    end

    test "includes cc, bcc and reply_to only when present" do
      mail = Mail.new do
        from "noreply@leedox.up.railway.app"
        to "user@example.com"
        cc "cc@example.com"
        reply_to "support@example.com"
        subject "Hello"
        body "plain text body"
      end

      payload = JSON.parse(deliver(mail).last_request.body)

      assert_equal [ "cc@example.com" ], payload["cc"]
      assert_equal [ "support@example.com" ], payload["reply_to"]
      assert_nil payload["bcc"]
      assert_equal "plain text body", payload["text"]
    end

    test "raises with the response status and body when the API call fails" do
      mail = Mail.new do
        from "noreply@leedox.up.railway.app"
        to "user@example.com"
        subject "x"
        body "x"
      end

      error = assert_raises(RuntimeError) do
        deliver(mail, response: error_response("422", '{"name":"validation_error","message":"Invalid `from` field"}'))
      end

      assert_match "422", error.message
      assert_match "validation_error", error.message
    end

    test "does not raise for any 2xx response" do
      mail = Mail.new do
        from "noreply@leedox.up.railway.app"
        to "user@example.com"
        subject "x"
        body "x"
      end

      request = deliver(mail, response: ok_response).last_request
      assert_not_nil request
    end

    test "defaults connection timeouts to 5s/10s and honors overrides via settings" do
      default_delivery = DeliveryMethods::ResendApi.new(api_key: "re_test_key")
      assert_equal(
        { use_ssl: true, open_timeout: 5, read_timeout: 10 },
        default_delivery.send(:connection_options)
      )

      custom_delivery = DeliveryMethods::ResendApi.new(api_key: "re_test_key", open_timeout: 2, read_timeout: 3)
      assert_equal(
        { use_ssl: true, open_timeout: 2, read_timeout: 3 },
        custom_delivery.send(:connection_options)
      )
    end
  end
end
