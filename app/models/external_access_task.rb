class ExternalAccessTask < ApplicationRecord
  TASK_TYPES = %w[
    verify_account send_invite confirm_acceptance revoke_access
    confirm_revocation process_account_change
  ].freeze
  STATUSES = %w[pending completed failed canceled].freeze
  OPEN_STATUSES = %w[pending failed].freeze
  REASON_CODES = %w[
    account_not_found identity_mismatch account_in_use manual_check_required
    invite_failed acceptance_not_confirmed revoke_failed revocation_not_confirmed other
  ].freeze

  belongs_to :external_account_link
  belongs_to :external_access_grant, optional: true
  belongs_to :license, optional: true
  belongs_to :product, optional: true
  belongs_to :processed_by, class_name: "User", optional: true
  has_many :external_access_events, dependent: :restrict_with_error

  before_validation :assign_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true
  validates :dedup_key, presence: true
  validates :task_type, inclusion: { in: TASK_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :reason_code, inclusion: { in: REASON_CODES }, allow_nil: true
  validates :evidence_note, :public_message, :internal_note, length: { maximum: 1_000 }, allow_blank: true
  validate :one_open_task

  scope :open, -> { where(status: OPEN_STATUSES) }

  def overdue?(at = Time.current)
    OPEN_STATUSES.include?(status) && due_at < at
  end

  private

  def assign_public_id
    self.public_id ||= SecureRandom.hex(12)
  end

  def one_open_task
    return unless OPEN_STATUSES.include?(status) && dedup_key.present?

    conflict = self.class.open.where(dedup_key: dedup_key).where.not(id: id).exists?
    errors.add(:dedup_key, "already has an open task") if conflict
  end
end
