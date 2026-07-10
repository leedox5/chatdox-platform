class BillingController < ApplicationController
  before_action :authenticate_user!

  def checkout
    @order_id = "chatdox-#{current_user.id}-#{Time.current.to_i}"
    @amount = payment_amount
    @currency = payment_currency
    @payment_provider = payment_provider
    @portone_store_id = ENV.fetch("PORTONE_STORE_ID", "")
    @portone_channel_key = ENV.fetch("PORTONE_CHANNEL_KEY", "")
    prepare_pending_portone_payment! if @payment_provider == "portone"
  end

  def success
    gateway = Payments::Gateway.current
    provider = gateway.provider
    payment_attributes =
      if provider == "portone"
        complete_portone_payment(gateway)
      else
        complete_toss_payment(gateway)
      end
    subscription = current_user.subscription || current_user.build_subscription
    update_subscription_for_payment!(subscription, payment_attributes)

    respond_to_payment_success
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.fatal(
      "Payment persistence error: provider=#{provider} " \
      "payment_id=#{payment_id_param} order_id=#{params[:orderId]} error=#{e.message}"
    )
    respond_to_payment_reconciliation_failure
  rescue StandardError => e
    Rails.logger.error("#{provider || 'unknown'} payment confirm error: #{e.message}")
    respond_to_payment_failure
  end

  def cancel
    redirect_to dashboard_path, alert: "결제가 취소되었습니다."
  end

  private

  def complete_toss_payment(gateway)
    payment = gateway.confirm_payment!(
      payment_key: params[:paymentKey],
      order_id: params[:orderId],
      amount: payment_amount
    )

    {
      provider: "toss",
      provider_customer_id: "user-#{current_user.id}",
      provider_payment_id: payment.fetch("paymentKey"),
      order_id: payment.fetch("orderId"),
      amount: payment.fetch("totalAmount"),
      currency: payment.fetch("currency", payment_currency),
      provider_payload: payment,
      toss_attributes: {
        toss_customer_key: "user-#{current_user.id}",
        toss_payment_key: payment.fetch("paymentKey")
      }
    }
  end

  def complete_portone_payment(gateway)
    payment_id = params[:paymentId].presence || params[:orderId]
    payment = gateway.verify_payment!(
      payment_id: payment_id,
      expected_amount: payment_amount,
      expected_currency: payment_currency
    )

    {
      provider: "portone",
      provider_customer_id: "user-#{current_user.id}",
      provider_payment_id: payment["id"] || payment["paymentId"] || payment_id,
      order_id: payment_id,
      amount: payment.dig("amount", "total"),
      currency: payment.fetch("currency", payment_currency),
      provider_payload: payment
    }
  end

  def update_subscription_for_payment!(subscription, attributes)
    ApplicationRecord.transaction do
      subscription.update!(
        {
          provider: attributes.fetch(:provider),
          provider_customer_id: attributes.fetch(:provider_customer_id),
          billing_key: subscription.billing_key,
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
    Payments::Gateway.current.provider
  end

  def payment_amount
    ENV.fetch("PAYMENT_PRICE_AMOUNT", ENV.fetch("TOSS_PRICE_AMOUNT", "9900")).to_i
  end

  def payment_currency
    ENV.fetch("PAYMENT_CURRENCY", "KRW")
  end

  def prepare_pending_portone_payment!
    subscription = current_user.subscription || current_user.build_subscription(
      provider: "portone",
      provider_customer_id: "user-#{current_user.id}",
      status: "pending",
      active: false
    )
    subscription.provider ||= "portone"
    subscription.provider_customer_id ||= "user-#{current_user.id}"
    subscription.status ||= "pending"
    subscription.save! if subscription.new_record? || subscription.changed?

    subscription.payment_transactions.find_or_create_by!(
      provider: "portone",
      provider_payment_id: @order_id
    ) do |transaction|
      transaction.order_id = @order_id
      transaction.status = "pending"
      transaction.amount = @amount
      transaction.currency = @currency
      transaction.provider_payload = {}
    end
  end

  def respond_to_payment_success
    if json_payment_request?
      render json: { ok: true, redirectUrl: dashboard_path }, status: :ok
    else
      redirect_to dashboard_path, notice: "결제가 완료되었습니다."
    end
  end

  def respond_to_payment_failure
    if json_payment_request?
      render json: { ok: false, message: "결제 승인에 실패했습니다." }, status: :unprocessable_entity
    else
      redirect_to billing_cancel_path, alert: "결제 승인에 실패했습니다."
    end
  end

  def respond_to_payment_reconciliation_failure
    message = "결제는 확인됐지만 구독 반영에 실패했습니다. 고객센터에 문의해 주세요."

    if json_payment_request?
      render json: { ok: false, message: message }, status: :internal_server_error
    else
      redirect_to dashboard_path, alert: message
    end
  end

  def json_payment_request?
    request.post? && request.media_type == "application/json"
  end

  def payment_id_param
    params[:paymentId].presence || params[:paymentKey]
  end
end
