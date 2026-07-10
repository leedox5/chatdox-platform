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

    status = subscription_status(payment["status"])

    ApplicationRecord.transaction do
      subscription.update!(status: status, active: status == "active")
      subscription.payment_transactions.find_or_initialize_by(
        provider: "toss",
        provider_payment_id: payment["paymentKey"]
      ).update!(
        order_id: payment["orderId"] || subscription.order_id,
        status: status,
        amount: payment["totalAmount"] || 0,
        currency: payment["currency"] || "KRW",
        provider_payload: payment
      )
    end
    head :ok
  rescue JSON::ParserError => e
    Rails.logger.warn("Toss webhook parse error: #{e.message}")
    head :bad_request
  rescue StandardError => e
    Rails.logger.error("Toss webhook error: #{e.message}")
    head :internal_server_error
  end

  private

  def subscription_status(provider_status)
    case provider_status
    when "DONE"
      "active"
    when "CANCELED", "PARTIAL_CANCELED"
      "canceled"
    when "ABORTED", "EXPIRED"
      "past_due"
    else
      "pending"
    end
  end
end
