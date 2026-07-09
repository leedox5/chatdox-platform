class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def user_not_authorized
    flash[:alert] = if current_user.present?
      "이 작업을 할 권한이 없습니다."
    else
      "로그인 후 이용 가능합니다."
    end

    redirect_to(current_user.present? ? root_path : new_user_session_path)
  end
end
