class PaymentTransaction < ApplicationRecord
  STATUSES = %w[pending active canceled past_due].freeze

  belongs_to :subscription, optional: true
  belongs_to :purchase_order, class_name: "Order", optional: true,
    inverse_of: :payment_transaction

  validates :provider, inclusion: { in: Payments::Gateway::PROVIDERS }
  validates :provider_payment_id, :order_id, :amount, :currency, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :provider_payment_id, uniqueness: { scope: :provider }
  validates :order_id, uniqueness: true
  validates :purchase_order_id, uniqueness: true, allow_nil: true
  validate :payment_owner_is_present

  private

  def payment_owner_is_present
    return if subscription.present? || purchase_order.present?

    errors.add(:base, "payment transaction requires a subscription or purchase order")
  end
end
