class PaymentTransaction < ApplicationRecord
  STATUSES = %w[pending active canceled past_due].freeze

  belongs_to :purchase_order, class_name: "Order", inverse_of: :payment_transaction
  has_many :commerce_audit_events, as: :auditable, dependent: :restrict_with_error

  validates :provider, inclusion: { in: Payments::Gateway::PROVIDERS }
  validates :provider_payment_id, :order_id, :amount, :currency, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :provider_payment_id, uniqueness: { scope: :provider }
  validates :order_id, uniqueness: true
  validates :purchase_order_id, uniqueness: true
end
