class ServiceDesk::Api::JobsController < ServiceDesk::Api::BaseController
  def create
    service_desk_request = ServiceDeskRequest.find_by(request_number: params[:request_id].to_i)
    return render(json: { error: "request not found" }, status: :not_found) unless service_desk_request

    job = service_desk_request.service_desk_jobs.build(job_params)

    if job.save
      render json: job_json(job), status: :created
    else
      render json: { errors: job.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def job_params
    params.permit(:author, :content)
  end

  def job_json(job)
    {
      request_number: job.service_desk_request.request_number,
      job_number: job.job_number,
      author: job.author,
      performed_at: job.performed_at.iso8601,
      content: job.content
    }
  end
end
