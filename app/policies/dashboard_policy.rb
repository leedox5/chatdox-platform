class DashboardPolicy < ApplicationPolicy
  def access?
    user.present?
  end

  def show_subscription?
    user.present? && (user.trial_active? || user.subscribed?)
  end

  def admin_access?
    user&.admin?
  end
end
