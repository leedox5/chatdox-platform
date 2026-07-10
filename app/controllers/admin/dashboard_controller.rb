class Admin::DashboardController < Admin::BaseController
  def show
    @total_users = User.count
    @admin_users = User.admin.count
    @active_subscriptions = Subscription.where(status: "active").count
    @trial_users = User.where(created_at: 7.days.ago..).count
    @recent_users = User.order(created_at: :desc).limit(5)
    @recent_transactions = PaymentTransaction.order(created_at: :desc).limit(5)
  end
end
