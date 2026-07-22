class MypageController < ApplicationController
  before_action :authenticate_user!

  def show
    @licenses = current_user.licenses.includes(:product).order(starts_on: :asc)
    @orders = current_user.orders.includes(:order_items).order(created_at: :desc).limit(10)
  end
end
