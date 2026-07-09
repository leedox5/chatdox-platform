class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :subscription, dependent: :destroy

  enum :role, { user: 0, admin: 1 }

  def trial_started_at
    created_at
  end

  def trial_remaining_seconds
    remaining = (trial_started_at + 7.days) - Time.current
    remaining.to_i.positive? ? remaining.to_i : 0
  end

  def trial_days_remaining
    days = (trial_remaining_seconds / 86_400.0).ceil
    days.positive? ? days : 0
  end

  def trial_active?
    trial_remaining_seconds.positive?
  end

  def subscribed?
    subscription&.active? || false
  end

  def can_view_chapter?(chapter_num)
    chapter_number = chapter_num.to_i

    return true if admin?
    return true if subscribed?
    return true if trial_active? && chapter_number <= 5

    chapter_number <= 2
  end
end
