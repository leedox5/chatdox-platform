class ChapterProgressesController < ApplicationController
  before_action :authenticate_user!

  def create
    chapter = Curriculum.find(params[:chapter_id])
    return head :not_found unless chapter

    authorize chapter, :view?, policy_class: DocPolicy

    complete_chapter_progress(chapter)

    redirect_to doc_path(chapter[:id]), notice: "완료한 챕터로 표시했습니다."
  end

  def destroy
    chapter = Curriculum.find(params[:chapter_id])
    return head :not_found unless chapter

    authorize chapter, :view?, policy_class: DocPolicy

    current_user.chapter_progresses.find_by(chapter_id: chapter[:id])&.destroy!

    redirect_to doc_path(chapter[:id]), notice: "완료 표시를 취소했습니다."
  end

  private

  def complete_chapter_progress(chapter)
    progress = current_user.chapter_progresses.find_or_initialize_by(chapter_id: chapter[:id])
    progress.update!(completed_at: Time.current)
  rescue ActiveRecord::RecordNotUnique
    current_user.chapter_progresses.find_by!(chapter_id: chapter[:id]).update!(completed_at: Time.current)
  end
end
