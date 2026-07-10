class Subscription < ApplicationRecord
  belongs_to :user

  validates :toss_customer_key, :order_id, :status, presence: true
end
