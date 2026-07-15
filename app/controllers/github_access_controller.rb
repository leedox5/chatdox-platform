class GithubAccessController < ApplicationController
  before_action :authenticate_user!

  def show
    load_links
  end

  def create
    link = ExternalAccess::LinkSubmission.call!(user: current_user, username: link_params.fetch(:username))
    redirect_to github_access_path, notice: "GitHub 계정 확인 요청을 접수했습니다."
  rescue ExternalAccess::LinkSubmission::Unavailable, ActiveRecord::RecordInvalid, KeyError
    redirect_to github_access_path, alert: "GitHub 사용자명과 기존 연결 상태를 확인해 주세요."
  end

  def change
    current_link = current_user.external_account_links.find_by!(public_id: link_params.fetch(:link_id))
    ExternalAccess::AccountChangeRequest.call!(
      user: current_user,
      current_link: current_link,
      username: link_params.fetch(:username)
    )
    redirect_to github_access_path, notice: "계정 변경 요청을 접수했습니다. 기존 권한 회수 후 새 계정을 확인합니다."
  rescue ExternalAccess::AccountChangeRequest::Unavailable, ActiveRecord::RecordInvalid, KeyError
    redirect_to github_access_path, alert: "계정 변경 조건과 사용자명을 확인해 주세요."
  end

  def disconnect
    link = current_user.external_account_links.find_by!(public_id: link_params.fetch(:link_id))
    ExternalAccess::DisconnectRequest.call!(user: current_user, link: link)
    redirect_to github_access_path, notice: "연결 해제 요청을 접수했습니다. 활성 권한은 회수 확인 후 해제됩니다."
  rescue ExternalAccess::DisconnectRequest::Unavailable, ActiveRecord::RecordInvalid, KeyError
    redirect_to github_access_path, alert: "연결 해제 상태를 확인해 주세요."
  end

  private

  def load_links
    @links = current_user.external_account_links.includes(
      external_access_grants: [ :product, :license, :external_access_tasks ]
    ).order(created_at: :desc)
    @available_link = @links.find { |link| link.status != "disabled" && link.replaces_link_id.nil? }
  end

  def link_params
    params.require(:external_account_link).permit(:username, :link_id)
  end
end
