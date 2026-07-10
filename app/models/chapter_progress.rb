class ChapterProgress < ApplicationRecord
  belongs_to :user

  validates :chapter_id,
    presence: true,
    uniqueness: { scope: :user_id },
    inclusion: { in: ->(_progress) { Curriculum.all.pluck(:id) } }

  scope :completed, -> { where.not(completed_at: nil) }

  def completed?
    completed_at.present?
  end
end
