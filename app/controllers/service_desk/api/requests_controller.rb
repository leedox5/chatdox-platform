class ServiceDesk::Api::RequestsController < ServiceDesk::Api::BaseController
  def create
    service_desk_request = ServiceDeskRequest.new(request_params)

    if service_desk_request.save
      render json: request_json(service_desk_request), status: :created
    else
      render json: { errors: service_desk_request.errors.full_messages }, status: :unprocessable_content
    end
  end

  def show
    service_desk_request = ServiceDeskRequest.find_by(request_number: params[:id].to_i)
    return render(json: { error: "not found" }, status: :not_found) unless service_desk_request

    render json: request_json(service_desk_request).merge(jobs: service_desk_request.service_desk_jobs.map { |job| job_json(job) })
  end

  def index
    requests = ServiceDeskRequest.includes(:service_desk_jobs).order(request_number: :desc)
    render json: requests.map { |service_desk_request| summary_json(service_desk_request) }
  end

  private

  def request_params
    params.permit(:subject, :requester, :visibility, :description)
  end

  def request_json(service_desk_request)
    {
      request_number: service_desk_request.request_number,
      subject: service_desk_request.subject,
      requester: service_desk_request.requester,
      status: service_desk_request.status_label,
      visibility: service_desk_request.visibility_label,
      description: service_desk_request.description
    }
  end

  def summary_json(service_desk_request)
    {
      request_number: service_desk_request.request_number,
      subject: service_desk_request.subject,
      status: service_desk_request.status_label,
      visibility: service_desk_request.visibility_label,
      job_count: service_desk_request.service_desk_jobs.size
    }
  end

  def job_json(job)
    {
      job_number: job.job_number,
      author: job.author,
      performed_at: job.performed_at.iso8601,
      content: job.content
    }
  end
end
