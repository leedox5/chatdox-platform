class Webhooks::TossPaymentsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def receive
    configuration = Payments::Configuration.new(provider: "toss")
    unless configuration.webhook_ready?
      Commerce::EventLogger.log(
        event: "commerce.gate_configuration_mismatch",
        provider: "toss",
        status: "webhook_configuration_missing"
      )
      return head :service_unavailable
    end

    payload = JSON.parse(request.raw_post)

    unless ActiveSupport::SecurityUtils.secure_compare(
      payload["secret"].to_s,
      ENV.fetch("TOSS_WEBHOOK_SECRET", "")
    )
      return head :bad_request
    end

    payment = TossPayments::Client.get_json("/v1/payments/#{payload['paymentKey']}")

    if (order = Order.find_by(public_id: payment["orderId"]))
      sync_purchase_order!(order, payment)
      return head :ok
    end

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
  rescue JSON::ParserError
    log_webhook_failure("invalid_json")
    head :bad_request
  rescue StandardError
    log_webhook_failure("processing_failed")
    head :internal_server_error
  end

  private

  def sync_purchase_order!(order, payment)
    attributes = {
      provider: "toss",
      provider_payment_id: payment.fetch("paymentKey"),
      order_id: payment.fetch("orderId"),
      amount: payment.fetch("totalAmount"),
      currency: payment.fetch("currency", "KRW"),
      provider_payload: payment
    }

    if payment["status"] == "DONE"
      Commerce::OrderFinalizer.call!(order: order, payment: attributes)
    else
      Commerce::OrderStatusSync.call!(
        order: order,
        status: subscription_status(payment["status"]),
        payment: attributes
      )
    end
  end

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

  def log_webhook_failure(status)
    Commerce::EventLogger.log(
      event: "commerce.webhook_processing_failed",
      provider: "toss",
      order: Order.find_by(public_id: params[:orderId]),
      status: status
    )
  end
end
