class Subscription < ApplicationRecord
  belongs_to :user

  scope :active, -> { where(active: true) }
end