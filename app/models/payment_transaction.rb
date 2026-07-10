class PaymentTransaction < ApplicationRecord
  PROVIDERS = %w[toss portone].freeze

  belongs_to :subscription

  validates :provider, inclusion: { in: PROVIDERS }
  validates :provider_payment_id, :order_id, :status, :amount, :currency, presence: true
  validates :provider_payment_id, uniqueness: { scope: :provider }
  validates :order_id, uniqueness: true
end
