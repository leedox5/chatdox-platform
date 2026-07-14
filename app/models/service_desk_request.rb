class ServiceDeskRequest < ApplicationRecord
  # New DB-backed requests continue numbering after the highest ID the git-based
  # service-desk (HQ) had reached at migration time, so the two independent
  # systems don't visually collide even though nothing keeps them in sync.
  MIN_SEEDED_REQUEST_NUMBER = 23

  STATUS_LABELS = {
    "pending" => "New",
    "in_progress" => "In Progress",
    "completed" => "Completed",
    "confirmed" => "Confirmed"
  }.freeze

  VISIBILITY_LABELS = {
    "visible" => "Public",
    "restricted" => "Private"
  }.freeze

  has_many :service_desk_jobs, -> { order(:job_number) }, dependent: :destroy, inverse_of: :service_desk_request

  enum :status, { pending: 0, in_progress: 1, completed: 2, confirmed: 3 }
  enum :visibility, { visible: 0, restricted: 1 }

  validates :request_number, presence: true, uniqueness: true
  validates :requester, :subject, :date, presence: true

  before_validation :assign_request_number, on: :create
  before_validation :assign_date, on: :create

  def to_param
    request_number.to_s.rjust(4, "0")
  end

  def status_label
    STATUS_LABELS.fetch(status, status)
  end

  def visibility_label
    VISIBILITY_LABELS.fetch(visibility, visibility)
  end

  private

  def assign_request_number
    return if request_number.present?

    self.request_number = [ self.class.maximum(:request_number).to_i, MIN_SEEDED_REQUEST_NUMBER ].max + 1
  end

  def assign_date
    self.date ||= Date.current
  end
end
