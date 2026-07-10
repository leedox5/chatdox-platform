class Webhooks::TossPaymentsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def receive
    payload = JSON.parse(request.raw_post)

    unless ActiveSupport::SecurityUtils.secure_compare(
      payload["secret"].to_s,
      ENV.fetch("TOSS_WEBHOOK_SECRET", "")
    )
      return head :bad_request
    end

    payment = TossPayments::Client.get_json("/v1/payments/#{payload['paymentKey']}")

    subscription = Subscription.find_by(toss_payment_key: payment["paymentKey"])
    return head :ok unless subscription

    subscription.update!(status: payment["status"].downcase)
    head :ok
  rescue JSON::ParserError => e
    Rails.logger.warn("Toss webhook parse error: #{e.message}")
    head :bad_request
  rescue StandardError => e
    Rails.logger.error("Toss webhook error: #{e.message}")
    head :internal_server_error
  end
end
