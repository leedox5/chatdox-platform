class BillingOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_chatdox_sales_enabled
  before_action :ensure_payment_configuration

  def create
    order = Commerce::OrderCreator.call!(
      user: current_user,
      product_code: order_params.fetch(:product_code),
      offer_code: order_params.fetch(:offer_code),
      requested_start_on: order_params[:requested_start_on],
      provider: Payments::Configuration.current.provider
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

  def retry_preview
    @source_order = current_user.orders.includes(order_items: [ :product, :product_offer ]).find_by!(public_id: params[:id])
    @assessment = Commerce::PendingOrderAssessment.call(order: @source_order)
    unless retryable?(@source_order, @assessment)
      redirect_to dashboard_path, alert: "이 주문은 안전하게 재시도할 수 없습니다."
      return
    end

    @source_item = @source_order.order_items.first!
    @current_offer = Commerce::RetryOrder.current_offer(@source_order)
    raise ActiveRecord::RecordNotFound unless @current_offer

    @period = Commerce::LicenseScheduler.preview(
      user: current_user,
      product: @source_item.product,
      duration_months: @current_offer.duration_months,
      requested_start_on: Time.current.in_time_zone(Commerce::PeriodCalculator::KST).to_date
    )
  end

  def retry
    source_order = current_user.orders.find_by!(public_id: params[:id])
    order = Commerce::RetryOrder.call!(
      source_order: source_order,
      user: current_user,
      provider: Payments::Configuration.current.provider
    )
    redirect_to billing_order_path(order.public_id), notice: "현재 상품 조건으로 새 주문을 만들었습니다."
  rescue Commerce::RetryOrder::Unavailable => e
    Rails.logger.warn("Commerce retry rejected: #{e.class.name}")
    redirect_to dashboard_path, alert: "결제 재시도 조건을 확인해 주세요."
  end

  private

  def order_params
    params.require(:order).permit(:product_code, :offer_code, :requested_start_on)
  end

  def ensure_chatdox_sales_enabled
    return if Commerce::Sales.enabled_for_code?("chatdox")

    redirect_to billing_checkout_path, alert: "신규 결제는 준비 중입니다."
  end

  def ensure_payment_configuration
    configuration = Payments::Configuration.current
    return if configuration.ready?

    Commerce::EventLogger.log(
      event: "commerce.gate_configuration_mismatch",
      provider: configuration.provider,
      status: "missing_configuration"
    )
    redirect_to billing_checkout_path, alert: "결제 설정을 준비 중입니다."
  end

  def retryable?(order, assessment)
    order.status == "abandoned" || (order.status == "pending" && assessment.safe_to_abandon)
  end
end
