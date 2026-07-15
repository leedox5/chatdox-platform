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
    if (order = Order.find_by(public_id: provider_payment_id))
      sync_purchase_order!(order, payment, provider_payment_id)
      return
    end

    transaction = PaymentTransaction.find_or_initialize_by(
      provider: "portone",
      provider_payment_id: provider_payment_id
    )
    subscription = transaction.subscription
    unless subscription
      Rails.logger.warn("PortOne webhook missing pending transaction: payment_id=#{provider_payment_id}")
      return
    end

    status = subscription_status(payment["status"])
    order_id = transaction.order_id.presence || provider_payment_id

    ApplicationRecord.transaction do
      transaction.update!(
        subscription: subscription,
        order_id: order_id,
        status: status,
        amount: payment.dig("amount", "total") || transaction.amount || 0,
        currency: payment["currency"] || transaction.currency || "KRW",
        provider_payload: payment
      )
      subscription.update!(subscription_attributes(subscription, status, order_id))
    end
  end

  def sync_purchase_order!(order, payment, provider_payment_id)
    attributes = {
      provider: "portone",
      provider_payment_id: provider_payment_id,
      order_id: order.public_id,
      amount: payment.dig("amount", "total") || 0,
      currency: payment["currency"] || "KRW",
      provider_payload: payment
    }

    if payment["status"] == "PAID"
      Commerce::OrderFinalizer.call!(order: order, payment: attributes)
    else
      Commerce::OrderStatusSync.call!(
        order: order,
        status: subscription_status(payment["status"]),
        payment: attributes
      )
    end
  end

  def subscription_attributes(subscription, status, order_id)
    attributes = { status: status, active: status == "active" }
    return attributes unless status == "active"

    attributes.merge(
      provider: "portone",
      provider_customer_id: subscription.provider_customer_id.presence || "user-#{subscription.user_id}",
      order_id: order_id
    )
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
