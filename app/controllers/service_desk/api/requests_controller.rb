class ServiceDesk::Api::RequestsController < ServiceDesk::Api::BaseController
  def create
    service_desk_request = ServiceDeskRequest.new(request_params)

    if service_desk_request.save
      render json: request_json(service_desk_request), status: :created
    else
      render json: { errors: service_desk_request.errors.full_messages }, status: :unprocessable_content
    end
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
end
