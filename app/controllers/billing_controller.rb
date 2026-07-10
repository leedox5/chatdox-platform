class BillingController < ApplicationController
  before_action :authenticate_user!

  def checkout
    @order_id = "chatdox-#{current_user.id}-#{Time.current.to_i}"
    @amount = ENV.fetch("TOSS_PRICE_AMOUNT", "9900").to_i
  end

  def success
    payment = TossPayments::Client.post_json(
      "/v1/payments/confirm",
      {
        paymentKey: params[:paymentKey],
        orderId: params[:orderId],
        amount: params[:amount].to_i
      }
    )

    record = current_user.subscription || current_user.build_subscription
    record.update!(
      toss_customer_key: "user-#{current_user.id}",
      toss_payment_key: payment["paymentKey"],
      order_id: payment["orderId"],
      status: payment["status"].downcase,
      current_period_start: Time.current,
      current_period_end: 1.month.from_now
    )

    redirect_to dashboard_path, notice: "결제가 완료되었습니다."
  rescue StandardError => e
    Rails.logger.error("Toss Payments confirm error: #{e.message}")
    redirect_to billing_cancel_path, alert: "결제 승인에 실패했습니다."
  end

  def cancel
    redirect_to dashboard_path, alert: "결제가 취소되었습니다."
  end
end
