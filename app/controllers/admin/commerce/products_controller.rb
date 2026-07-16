class Admin::Commerce::ProductsController < Admin::BaseController
  def index
    @products = Product.includes(:product_offers).order(:code)
  end

  def update
    product = Product.find(params[:id])
    from_state = product.sale_enabled? ? "enabled" : "disabled"
    product.update!(sale_enabled: !product.sale_enabled?)
    to_state = product.sale_enabled? ? "enabled" : "disabled"

    Commerce::AuditRecorder.record!(
      actor: current_user,
      action: "product_sale_toggled",
      auditable: product,
      from_state: from_state,
      to_state: to_state
    )

    redirect_to admin_commerce_products_path, notice: "#{product.name}의 판매 상태를 변경했습니다."
  end
end
