# Base for AI-agent-facing service desk endpoints (Claudox, Platform Agent,
# etc.) that have no browser session and so can't use authenticate_user!.
# A single fixed bearer token is intentional here — see leedox_service_desk_db_r1
# request.md section E: OAuth or per-agent keys are explicitly out of scope.
class ServiceDesk::Api::BaseController < ActionController::Base
  skip_before_action :verify_authenticity_token, raise: false
  before_action :authenticate_token!

  private

  def authenticate_token!
    expected = ENV["SERVICE_DESK_API_TOKEN"].to_s
    provided = request.headers["Authorization"].to_s.delete_prefix("Bearer ")

    return if expected.present? && ActiveSupport::SecurityUtils.secure_compare(expected, provided)

    render json: { error: "unauthorized" }, status: :unauthorized
  end
end
