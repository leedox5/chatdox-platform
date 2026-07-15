class Order < ApplicationRecord
  STATUSES = %w[pending paid failed canceled].freeze
  TRANSITIONS = {
    "pending" => %w[paid failed canceled],
    "paid" => [],
    "failed" => [],
    "canceled" => []
  }.freeze
  SNAPSHOT_FIELDS = %w[
    user_id public_id provider requested_start_on supply_amount vat_amount
    total_amount currency payment_requested_at
  ].freeze

  belongs_to :user
  has_many :order_items, dependent: :restrict_with_error
  has_many :licenses, through: :order_items
  has_one :payment_transaction, foreign_key: :purchase_order_id,
    dependent: :restrict_with_error, inverse_of: :purchase_order

  validates :public_id, presence: true, uniqueness: true
  validates :provider, inclusion: { in: Payments::Gateway::PROVIDERS }
  validates :status, inclusion: { in: STATUSES }
  validates :requested_start_on, :payment_requested_at, :currency, presence: true
  validates :supply_amount, :vat_amount, :total_amount,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :amounts_add_up
  validate :snapshot_is_immutable, on: :update

  def transition_to!(target, attributes = {})
    target = target.to_s
    return self if status == target

    unless TRANSITIONS.fetch(status).include?(target)
      raise ArgumentError, "invalid order transition: #{status} -> #{target}"
    end

    update!(attributes.merge(status: target))
  end

  private

  def amounts_add_up
    return if supply_amount.blank? || vat_amount.blank? || total_amount.blank?
    return if supply_amount + vat_amount == total_amount

    errors.add(:total_amount, "must equal supply amount plus VAT")
  end

  def snapshot_is_immutable
    changed_snapshot_fields = changes_to_save.keys & SNAPSHOT_FIELDS
    return if changed_snapshot_fields.empty?

    errors.add(:base, "order snapshot cannot be changed after creation")
  end
end
