class PaymentTransaction < ApplicationRecord
  STATUSES = %w[pending active canceled past_due].freeze

  belongs_to :subscription

  validates :provider, inclusion: { in: Payments::Gateway::PROVIDERS }
  validates :provider_payment_id, :order_id, :amount, :currency, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :provider_payment_id, uniqueness: { scope: :provider }
  validates :order_id, uniqueness: true
end
