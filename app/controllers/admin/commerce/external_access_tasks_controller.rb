class Admin::Commerce::ExternalAccessTasksController < Admin::BaseController
  def index
    @tasks = filtered_tasks.limit(100)
  end

  def show
    @task = task_scope.find_by!(public_id: params[:id])
    @link = @task.external_account_link
    @grant = @task.external_access_grant
    @events = @task.external_access_events.includes(:actor).order(occurred_at: :desc)
  end

  def update
    task = task_scope.find_by!(public_id: params[:id])
    ExternalAccess::TaskProcessor.call!(
      task: task,
      actor: current_user,
      action: task_params.fetch(:action_name),
      external_uid: task_params[:external_uid],
      evidence_note: task_params[:evidence_note],
      public_message: task_params[:public_message],
      internal_note: task_params[:internal_note],
      reason_code: task_params[:reason_code],
      retryable: task_params.fetch(:retryable, true)
    )
    redirect_to admin_commerce_external_access_task_path(task.public_id), notice: "수동 GitHub 작업 기록을 저장했습니다."
  rescue ExternalAccess::TaskProcessor::InvalidAction, ActiveRecord::RecordInvalid, KeyError
    redirect_to admin_commerce_external_access_task_path(params[:id]), alert: "허용되지 않은 작업 또는 상태 변경입니다."
  end

  private

  def task_scope
    ExternalAccessTask.includes(
      :processed_by,
      external_account_link: :user,
      external_access_grant: [ :product, :license ],
      license: :product
    )
  end

  def filtered_tasks
    scope = task_scope.order(due_at: :asc)
    scope = scope.where(task_type: params[:task_type]) if ExternalAccessTask::TASK_TYPES.include?(params[:task_type])
    scope = scope.where(status: params[:status]) if ExternalAccessTask::STATUSES.include?(params[:status])
    scope = scope.joins(:external_account_link).where(external_account_links: { status: params[:link_status] }) if ExternalAccountLink::STATUSES.include?(params[:link_status])
    scope = scope.joins(:external_access_grant).where(external_access_grants: { status: params[:grant_status] }) if ExternalAccessGrant::STATUSES.include?(params[:grant_status])
    scope = scope.joins(:product).where(products: { code: params[:product] }) if params[:product].present?
    scope = apply_due_filter(scope)
    apply_license_filter(scope)
  end

  def apply_due_filter(scope)
    case params[:due]
    when "overdue" then scope.where(status: ExternalAccessTask::OPEN_STATUSES).where("due_at < ?", Time.current)
    when "due" then scope.where(status: ExternalAccessTask::OPEN_STATUSES).where("due_at >= ?", Time.current)
    else scope
    end
  end

  def apply_license_filter(scope)
    case params[:license_status]
    when "scheduled" then scope.joins(:license).where("licenses.starts_on > ?", Time.current.in_time_zone(License::KST).to_date)
    when "active" then scope.joins(:license).where("licenses.starts_on <= ? AND licenses.access_ends_at > ?", Time.current.in_time_zone(License::KST).to_date, Time.current)
    when "expired" then scope.joins(:license).where("licenses.access_ends_at <= ?", Time.current)
    else scope
    end
  end

  def task_params
    params.require(:external_access_task).permit(
      :action_name, :external_uid, :evidence_note, :public_message,
      :internal_note, :reason_code, :retryable
    )
  end
end
