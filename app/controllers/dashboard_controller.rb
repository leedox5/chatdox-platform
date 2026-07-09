class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize current_user, :access?, policy_class: DashboardPolicy

    @trial_days_remaining = current_user.trial_days_remaining
    @subscription_active = current_user.subscribed?
    @accessible_chapters = DocsController::CHAPTERS.count do |chapter|
      current_user.can_view_chapter?(chapter[:id])
    end
  end
end