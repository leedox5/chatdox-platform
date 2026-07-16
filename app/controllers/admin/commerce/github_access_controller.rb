class Admin::Commerce::GithubAccessController < Admin::BaseController
  def index
    links = ExternalAccountLink.includes(:user).order(created_at: :asc).to_a
    active_user_ids = active_chatdox_license_user_ids

    @needs_invite = links.select { |link| link.needs_invite? && active_user_ids.include?(link.user_id) }
    @needs_revoke = links.select { |link| link.needs_revoke? && !active_user_ids.include?(link.user_id) }
  end

  def invite
    link = ExternalAccountLink.find_by!(public_id: params[:id])
    link.update!(invited_at: Time.current)
    redirect_to admin_commerce_github_access_path, notice: "초대 완료로 기록했습니다."
  end

  def revoke
    link = ExternalAccountLink.find_by!(public_id: params[:id])
    link.update!(revoked_at: Time.current)
    redirect_to admin_commerce_github_access_path, notice: "회수 완료로 기록했습니다."
  end

  private

  def active_chatdox_license_user_ids
    License.for_product("chatdox").not_canceled.select { |license| license.active_at? }.map(&:user_id).to_set
  end
end
