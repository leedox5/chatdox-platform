class License < ApplicationRecord
  SOURCES = %w[paid coupon legacy].freeze
  STATUSES = %w[scheduled active canceled].freeze
  KST = ActiveSupport::TimeZone["Asia/Seoul"]

  belongs_to :user
  belongs_to :product
  belongs_to :order_item, optional: true
  has_many :external_access_grants, dependent: :restrict_with_error
  has_many :external_access_tasks, dependent: :restrict_with_error

  validates :source, inclusion: { in: SOURCES }
  validates :status, inclusion: { in: STATUSES }
  validates :starts_on, :last_usable_on, :access_ends_at, presence: true
  validates :order_item_id, uniqueness: true, allow_nil: true
  validate :period_is_ordered

  scope :for_product, ->(code) { joins(:product).where(products: { code: code }) }
  scope :not_canceled, -> { where.not(status: "canceled") }

  def active_at?(time = Time.current)
    return false if status == "canceled"

    time >= starts_at && time < access_ends_at
  end

  def effective_status(at: Time.current)
    return "canceled" if status == "canceled"
    return "scheduled" if at < starts_at
    return "active" if at < access_ends_at

    "expired"
  end

  def starts_at
    KST.local(starts_on.year, starts_on.month, starts_on.day)
  end

  private

  def period_is_ordered
    return if starts_on.blank? || last_usable_on.blank? || access_ends_at.blank?

    errors.add(:last_usable_on, "must not be before the start date") if last_usable_on < starts_on
    expected_end = KST.local(
      (last_usable_on + 1.day).year,
      (last_usable_on + 1.day).month,
      (last_usable_on + 1.day).day
    )
    errors.add(:access_ends_at, "must be the next KST midnight") unless access_ends_at == expected_end
  end
end
