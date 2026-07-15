class ProductOffer < ApplicationRecord
  belongs_to :product
  has_many :order_items, dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: true
  validates :version, :duration_months, numericality: { only_integer: true, greater_than: 0 }
  validates :supply_amount, :vat_amount, :total_amount,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :discount_bps,
    numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 10_000 }
  validates :currency, presence: true
  validates :duration_months, uniqueness: { scope: %i[product_id version] }
  validate :amounts_add_up
  validate :availability_window_is_ordered

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:duration_months, :version) }

  def available_at?(time = Time.current)
    active? &&
      (available_from.blank? || available_from <= time) &&
      (available_until.blank? || available_until > time)
  end

  private

  def amounts_add_up
    return if supply_amount.blank? || vat_amount.blank? || total_amount.blank?
    return if supply_amount + vat_amount == total_amount

    errors.add(:total_amount, "must equal supply amount plus VAT")
  end

  def availability_window_is_ordered
    return if available_from.blank? || available_until.blank? || available_from < available_until

    errors.add(:available_until, "must be after the availability start")
  end
end
