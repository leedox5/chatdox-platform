class Subscription < ApplicationRecord
  belongs_to :user
  has_many :payment_transactions, dependent: :restrict_with_error

  validates :provider, inclusion: { in: Payments::Gateway::PROVIDERS }
  validates :provider_customer_id, :status, presence: true
end
