class BillingController < ApplicationController
  before_action :authenticate_user!

  def checkout
    @order_id = "chatdox-#{current_user.id}-#{Time.current.to_i}"
    @amount = payment_amount
    @currency = payment_currency
    @payment_provider = payment_provider
    @portone_store_id = ENV.fetch("PORTONE_STORE_ID", "")
    @portone_channel_key = ENV.fetch("PORTONE_CHANNEL_KEY", "")
  end

  def success
    payment_provider == "portone" ? complete_portone_payment : complete_toss_payment

    redirect_to dashboard_path, notice: "결제가 완료되었습니다."
  rescue StandardError => e
    Rails.logger.error("#{payment_provider} payment confirm error: #{e.message}")
    redirect_to billing_cancel_path, alert: "결제 승인에 실패했습니다."
  end

  def cancel
    redirect_to dashboard_path, alert: "결제가 취소되었습니다."
  end

  private

  def complete_toss_payment
    payment = Payments::TossGateway.new.confirm_payment!(
      payment_key: params[:paymentKey],
      order_id: params[:orderId],
      amount: payment_amount
    )

    subscription = current_user.subscription || current_user.build_subscription
    update_subscription_for_payment!(
      subscription,
      provider: "toss",
      provider_customer_id: "user-#{current_user.id}",
      billing_key: subscription.billing_key,
      provider_payment_id: payment.fetch("paymentKey"),
      order_id: payment.fetch("orderId"),
      amount: payment.fetch("totalAmount"),
      currency: payment.fetch("currency", payment_currency),
      provider_payload: payment,
      toss_attributes: {
        toss_customer_key: "user-#{current_user.id}",
        toss_payment_key: payment.fetch("paymentKey")
      }
    )
  end

  def complete_portone_payment
    payment_id = params[:paymentId].presence || params[:orderId]
    payment = Payments::PortoneGateway.new.verify_payment!(
      payment_id: payment_id,
      expected_amount: payment_amount,
      expected_currency: payment_currency
    )

    subscription = current_user.subscription || current_user.build_subscription
    update_subscription_for_payment!(
      subscription,
      provider: "portone",
      provider_customer_id: "user-#{current_user.id}",
      billing_key: subscription.billing_key,
      provider_payment_id: payment.fetch("id", payment_id),
      order_id: payment_id,
      amount: payment.dig("amount", "total"),
      currency: payment.fetch("currency", payment_currency),
      provider_payload: payment
    )
  end

  def update_subscription_for_payment!(subscription, attributes)
    ApplicationRecord.transaction do
      subscription.update!(
        {
          provider: attributes.fetch(:provider),
          provider_customer_id: attributes.fetch(:provider_customer_id),
          billing_key: attributes[:billing_key],
          order_id: attributes.fetch(:order_id),
          status: "active",
          active: true,
          current_period_start: Time.current,
          current_period_end: 1.month.from_now
        }.merge(attributes.fetch(:toss_attributes, {}))
      )

      transaction = subscription.payment_transactions.find_or_initialize_by(
        provider: attributes.fetch(:provider),
        provider_payment_id: attributes.fetch(:provider_payment_id)
      )
      transaction.update!(
        order_id: attributes.fetch(:order_id),
        status: "active",
        amount: attributes.fetch(:amount),
        currency: attributes.fetch(:currency),
        provider_payload: attributes.fetch(:provider_payload)
      )
    end
  end

  def payment_provider
    ENV.fetch("PAYMENT_PROVIDER", "toss")
  end

  def payment_amount
    ENV.fetch("PAYMENT_PRICE_AMOUNT", ENV.fetch("TOSS_PRICE_AMOUNT", "9900")).to_i
  end

  def payment_currency
    ENV.fetch("PAYMENT_CURRENCY", "KRW")
  end
end
