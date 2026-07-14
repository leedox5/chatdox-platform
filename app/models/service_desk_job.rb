class ServiceDeskJob < ApplicationRecord
  belongs_to :service_desk_request, inverse_of: :service_desk_jobs

  validates :author, :performed_at, presence: true
  validates :job_number, presence: true, uniqueness: { scope: :service_desk_request_id }

  before_validation :assign_job_number, on: :create
  before_validation :assign_performed_at, on: :create

  private

  def assign_job_number
    return if job_number.present? || service_desk_request.nil?

    self.job_number = (service_desk_request.service_desk_jobs.maximum(:job_number) || 0) + 1
  end

  def assign_performed_at
    self.performed_at ||= Time.current
  end
end
