class ChapterProgressesController < ApplicationController
  before_action :authenticate_user!

  def create
    chapter = find_chapter
    return head :not_found unless chapter

    authorize chapter, :view?, policy_class: DocPolicy

    complete_chapter_progress(chapter)

    redirect_to redirect_path(chapter), notice: "완료한 챕터로 표시했습니다."
  end

  def destroy
    chapter = find_chapter
    return head :not_found unless chapter

    authorize chapter, :view?, policy_class: DocPolicy

    current_user.chapter_progresses.find_by(chapter_id: chapter[:id], product_code: chapter[:product_code])&.destroy!

    redirect_to redirect_path(chapter), notice: "완료 표시를 취소했습니다."
  end

  private

  def find_chapter
    if params[:product_code] == "claudox"
      find_claudox_chapter(params[:chapter_id])
    else
      Curriculum.find(params[:chapter_id])&.merge(product_code: "chatdox")
    end
  end

  # Equivalent to ClaudoxController#available_chapters' lookup, but for a
  # single chapter id -- Claudox has no CHAPTERS-style constant, its valid
  # chapter list is derived from which markdown files exist on disk.
  def find_claudox_chapter(id)
    chapter_number = id.to_s.to_i
    return unless (1..20).cover?(chapter_number)

    # Build the glob pattern from the validated integer, not the raw param --
    # a raw string like "05/../../.." would still pass a naive rjust+to_i
    # check while smuggling path segments into Dir.glob.
    normalized_id = chapter_number.to_s.rjust(2, "0")
    file_path = Dir.glob(ClaudoxController::CLAUDOX_PATH.join("#{normalized_id}_*.md")).first
    return unless file_path

    { id: normalized_id, product_code: "claudox" }
  end

  def redirect_path(chapter)
    chapter[:product_code] == "claudox" ? claudox_chapter_path(chapter[:id]) : doc_path(chapter[:id])
  end

  def complete_chapter_progress(chapter)
    progress = current_user.chapter_progresses.find_or_initialize_by(
      chapter_id: chapter[:id], product_code: chapter[:product_code]
    )
    progress.update!(completed_at: Time.current)
  rescue ActiveRecord::RecordNotUnique
    current_user.chapter_progresses
      .find_by!(chapter_id: chapter[:id], product_code: chapter[:product_code])
      .update!(completed_at: Time.current)
  end
end
