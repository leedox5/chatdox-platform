class BillingAuthsController < ApplicationController
  before_action :authenticate_user!

  def create
    if Payments::Gateway.current.provider == "portone"
      activate_portone_billing_key
      return redirect_to dashboard_path, notice: "자동결제가 활성화되었습니다."
    end

    payment = TossPayments::Client.post_json(
      "/v1/billing/authorizations/issue",
      { authKey: params[:authKey], customerKey: "user-#{current_user.id}" }
    )

    record = current_user.subscription || current_user.build_subscription
    record.update!(
      provider: "toss",
      provider_customer_id: payment["customerKey"],
      billing_key: payment["billingKey"],
      toss_customer_key: payment["customerKey"],
      toss_billing_key: payment["billingKey"],
      order_id: record.order_id || "chatdox-#{current_user.id}-#{Time.current.to_i}",
      status: "active",
      active: true
    )

    redirect_to dashboard_path, notice: "자동결제가 활성화되었습니다."
  rescue StandardError => e
    Rails.logger.error("Billing auth error: #{e.message}")
    redirect_to dashboard_path, alert: "빌링키 발급에 실패했습니다."
  end

  private

  def activate_portone_billing_key
    raise "missing billing key" if params[:billingKey].blank?

    record = current_user.subscription || current_user.build_subscription
    record.update!(
      provider: "portone",
      provider_customer_id: "user-#{current_user.id}",
      billing_key: params[:billingKey],
      order_id: record.order_id || "chatdox-#{current_user.id}-#{Time.current.to_i}",
      status: "active",
      active: true
    )
  end
end
