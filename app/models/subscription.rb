class Subscription < ApplicationRecord
  PROVIDERS = %w[toss portone].freeze

  belongs_to :user
  has_many :payment_transactions, dependent: :destroy

  validates :provider, inclusion: { in: PROVIDERS }
  validates :provider_customer_id, :status, presence: true
end
