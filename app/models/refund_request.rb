class RefundRequest < ApplicationRecord
  STATUSES = %w[requested reviewing approved rejected processing refunded failed].freeze
  OPEN_STATUSES = %w[requested reviewing approved processing].freeze
  REASON_CODES = %w[before_service_start duplicate_payment system_error service_issue other].freeze
  PROVIDER_REFUND_STATUSES = %w[not_requested pending confirmed failed].freeze
  TRANSITIONS = {
    "requested" => %w[reviewing],
    "reviewing" => %w[approved rejected],
    "approved" => %w[processing],
    "rejected" => [],
    "processing" => %w[refunded failed],
    "refunded" => [],
    "failed" => []
  }.freeze
  SNAPSHOT_FIELDS = %w[user_id order_id public_id requested_amount full_request reason_code customer_note].freeze

  belongs_to :user
  belongs_to :order
  belongs_to :processed_by, class_name: "User", optional: true
  has_many :commerce_audit_events, as: :auditable, dependent: :restrict_with_error

  scope :open, -> { where(status: OPEN_STATUSES) }

  validates :public_id, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :reason_code, inclusion: { in: REASON_CODES }
  validates :provider_refund_status, inclusion: { in: PROVIDER_REFUND_STATUSES }
  validates :requested_amount, numericality: { only_integer: true, greater_than: 0 }
  validates :customer_note, length: { maximum: 1_000 }, allow_blank: true
  validates :public_response, :internal_note, length: { maximum: 2_000 }, allow_blank: true
  validate :order_belongs_to_user
  validate :paid_order_on_create, on: :create
  validate :full_amount_matches_order
  validate :only_one_open_request
  validate :snapshot_is_immutable, on: :update

  def open?
    OPEN_STATUSES.include?(status)
  end

  def transition_to!(target, attributes = {})
    target = target.to_s
    return self if target == status && attributes.empty?

    unless target == status || TRANSITIONS.fetch(status).include?(target)
      raise ArgumentError, "invalid refund transition: #{status} -> #{target}"
    end

    update!(attributes.merge(status: target))
  end

  private

  def order_belongs_to_user
    errors.add(:order, "must belong to the requester") if order && user && order.user_id != user_id
  end

  def paid_order_on_create
    errors.add(:order, "must be paid") unless order&.status == "paid"
  end

  def full_amount_matches_order
    return unless order && requested_amount

    errors.add(:requested_amount, "must match the paid order") unless full_request? && requested_amount == order.total_amount
  end

  def only_one_open_request
    return unless open? && order_id

    duplicate = self.class.open.where(order_id: order_id).where.not(id: id).exists?
    errors.add(:order, "already has an open refund request") if duplicate
  end

  def snapshot_is_immutable
    errors.add(:base, "refund request snapshot cannot be changed") if (changes_to_save.keys & SNAPSHOT_FIELDS).any?
  end
end
