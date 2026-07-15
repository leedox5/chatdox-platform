class BillingOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_chatdox_sales_enabled

  def create
    order = Commerce::OrderCreator.call!(
      user: current_user,
      product_code: order_params.fetch(:product_code),
      offer_code: order_params.fetch(:offer_code),
      requested_start_on: order_params[:requested_start_on],
      provider: Payments::Gateway.current.provider
    )

    redirect_to billing_order_path(order.public_id)
  rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid,
         Commerce::OrderCreator::Unavailable, ArgumentError => e
    Rails.logger.warn("Commerce order rejected: #{e.class.name}")
    redirect_to billing_checkout_path, alert: "주문 조건을 확인해 주세요."
  end

  def show
    @order = current_user.orders.includes(order_items: %i[product product_offer]).find_by!(public_id: params[:id])
    unless @order.status == "pending"
      redirect_to dashboard_path, notice: "이미 처리된 주문입니다."
      return
    end

    @order_item = @order.order_items.first!
    @period = Commerce::PeriodCalculator.call(
      start_on: @order.requested_start_on,
      duration_months: @order_item.duration_months
    )
    @portone_store_id = ENV.fetch("PORTONE_STORE_ID", "")
    @portone_channel_key = ENV.fetch("PORTONE_CHANNEL_KEY", "")
    @toss_client_key = ENV.fetch("TOSS_CLIENT_KEY", "")
    @payment_provider = @order.provider
  end

  private

  def order_params
    params.require(:order).permit(:product_code, :offer_code, :requested_start_on)
  end

  def ensure_chatdox_sales_enabled
    return if Commerce::Sales.enabled_for_code?("chatdox")

    redirect_to billing_checkout_path, alert: "신규 결제는 준비 중입니다."
  end
end
