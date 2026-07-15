class Admin::Commerce::ExternalAccountLinksController < Admin::BaseController
  def index
    @links = link_scope.order(created_at: :desc)
    @links = @links.where(status: params[:status]) if ExternalAccountLink::STATUSES.include?(params[:status])
    @links = @links.limit(100)
  end

  def show
    @link = link_scope.find_by!(public_id: params[:id])
    @grants = @link.external_access_grants.order(created_at: :desc)
    @tasks = @link.external_access_tasks.order(due_at: :desc)
    @events = @link.external_access_events.includes(:actor).order(occurred_at: :desc)
  end

  private

  def link_scope
    ExternalAccountLink.includes(
      :user,
      :replaces_link,
      :replacement_link,
      external_access_grants: [ :product, :license ],
      external_access_tasks: [ :product, :license, :external_access_grant ]
    )
  end
end
