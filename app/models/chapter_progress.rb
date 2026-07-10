class ChapterProgress < ApplicationRecord
  belongs_to :user

  validates :chapter_id,
    presence: true,
    uniqueness: { scope: :user_id },
    format: { with: /\A(0[1-9]|1[0-9]|20)\z/ }

  scope :completed, -> { where.not(completed_at: nil) }

  def completed?
    completed_at.present?
  end
end
