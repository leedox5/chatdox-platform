class BillingAuthsController < ApplicationController
  before_action :authenticate_user!

  def create
    payment = TossPayments::Client.post_json(
      "/v1/billing/authorizations/issue",
      { authKey: params[:authKey], customerKey: "user-#{current_user.id}" }
    )

    record = current_user.subscription || current_user.build_subscription
    record.update!(
      toss_customer_key: payment["customerKey"],
      toss_billing_key: payment["billingKey"],
      order_id: record.order_id || "chatdox-#{current_user.id}-#{Time.current.to_i}",
      status: "active"
    )

    redirect_to dashboard_path, notice: "자동결제가 활성화되었습니다."
  rescue StandardError => e
    Rails.logger.error("Toss billing auth error: #{e.message}")
    redirect_to dashboard_path, alert: "빌링키 발급에 실패했습니다."
  end
end
