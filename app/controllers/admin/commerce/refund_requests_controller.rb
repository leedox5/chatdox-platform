class Admin::Commerce::RefundRequestsController < Admin::BaseController
  def show
    @refund_request = refund_scope.find_by!(public_id: params[:id])
    @order = @refund_request.order
    @audits = @refund_request.commerce_audit_events.includes(:actor).order(occurred_at: :desc)
  end

  def update
    refund_request = refund_scope.find_by!(public_id: params[:id])
    Commerce::RefundRequestTransition.call!(
      refund_request: refund_request,
      actor: current_user,
      action: transition_params.fetch(:action_name),
      public_response: transition_params[:public_response],
      internal_note: transition_params[:internal_note]
    )
    redirect_to admin_commerce_refund_request_path(refund_request.public_id), notice: "환불 심사 기록을 저장했습니다."
  rescue ArgumentError, KeyError, ActiveRecord::RecordInvalid
    redirect_to admin_commerce_refund_request_path(params[:id]), alert: "허용되지 않은 상태 변경입니다."
  end

  private

  def refund_scope
    RefundRequest.includes(
      :user,
      :processed_by,
      order: [ :payment_transaction, :licenses, { order_items: [ :product, :license ] } ]
    ).strict_loading
  end

  def transition_params
    params.require(:refund_request).permit(:action_name, :public_response, :internal_note)
  end
end
