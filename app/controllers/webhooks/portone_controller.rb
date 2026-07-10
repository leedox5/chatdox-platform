class Webhooks::PortoneController < ApplicationController
  skip_before_action :verify_authenticity_token

  def receive
    raw_payload = request.raw_post
    Portone::WebhookVerifier.verify!(
      secret: ENV.fetch("PORTONE_WEBHOOK_SECRET", ""),
      payload: raw_payload,
      headers: request.headers
    )

    payload = JSON.parse(raw_payload)
    payment_id = payload.dig("data", "paymentId")
    return head :ok if payment_id.blank?

    payment = Payments::PortoneGateway.new.fetch_payment!(payment_id)
    sync_payment!(payment)

    head :ok
  rescue Portone::WebhookVerifier::VerificationError => e
    Rails.logger.warn("PortOne webhook verification error: #{e.message}")
    head :bad_request
  rescue JSON::ParserError => e
    Rails.logger.warn("PortOne webhook parse error: #{e.message}")
    head :bad_request
  rescue StandardError => e
    Rails.logger.error("PortOne webhook error: #{e.message}")
    head :internal_server_error
  end

  private

  def sync_payment!(payment)
    provider_payment_id = payment["id"] || payment["paymentId"]
    transaction = PaymentTransaction.find_by(provider: "portone", provider_payment_id: provider_payment_id)
    subscription = transaction&.subscription || subscription_from_payment_id(provider_payment_id)
    return unless subscription

    status = subscription_status(payment["status"])

    ApplicationRecord.transaction do
      transaction&.update!(
        status: status,
        amount: payment.dig("amount", "total") || transaction.amount,
        currency: payment["currency"] || transaction.currency,
        provider_payload: payment
      )
      subscription.update!(status: status, active: status == "active")
    end
  end

  def subscription_from_payment_id(payment_id)
    user_id = payment_id.to_s[/\Achatdox-(\d+)-/, 1]
    return unless user_id

    User.find_by(id: user_id)&.subscription
  end

  def subscription_status(provider_status)
    case provider_status
    when "PAID"
      "active"
    when "CANCELLED", "PARTIAL_CANCELLED"
      "canceled"
    when "FAILED"
      "past_due"
    else
      "pending"
    end
  end
end
