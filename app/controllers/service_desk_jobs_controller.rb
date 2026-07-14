class ServiceDeskJobsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_service_desk!

  def create
    service_desk_request = ServiceDeskRequest.find_by(request_number: params[:id].to_i)
    return render(plain: "요청을 찾을 수 없습니다.", status: :not_found) unless service_desk_request

    job = service_desk_request.service_desk_jobs.build(job_params)

    if job.save
      redirect_to service_desk_request_path(service_desk_request), notice: "작업 내용이 추가되었습니다."
    else
      redirect_to service_desk_request_path(service_desk_request), alert: job.errors.full_messages.to_sentence
    end
  end

  private

  def authorize_service_desk!
    authorize :admin, :access?
  end

  def job_params
    params.require(:service_desk_job).permit(:author, :content)
  end
end
