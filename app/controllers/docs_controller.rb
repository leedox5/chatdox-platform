class DocsController < ApplicationController
  DOCS_PATH = Rails.root.join("docs/curriculum/docs")

  def index
    @chapters = chapters_with_availability
    @phase_chapters = chapters_by_phase(@chapters)
  end

  def show
    request.format = :html

    @chapters = chapters_with_availability
    @phase_chapters = chapters_by_phase(@chapters)
    @current_id = params[:id].to_s.rjust(2, "0")
    @current_chapter = Curriculum.find(@current_id)

    unless @current_chapter
      render plain: "챕터를 찾을 수 없습니다.", status: :not_found
      return
    end

    authorize @current_chapter, :view?, policy_class: DocPolicy

    file_path = DOCS_PATH.join("#{File.basename(@current_chapter[:slug].to_s)}.md")
    unless File.exist?(file_path)
      render plain: "아직 공개되지 않은 챕터입니다.", status: :not_found
      return
    end

    raw_markdown = File.read(file_path)
    @chapter_progress = if user_signed_in?
      current_user.chapter_progresses.find_by(chapter_id: @current_id)
    end

    renderer = Redcarpet::Render::HTML.new(
      hard_wrap: true,
      link_attributes: { target: "_blank", rel: "noopener noreferrer" }
    )
    markdown = Redcarpet::Markdown.new(
      renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      superscript: true
    )

    @content_html = markdown.render(raw_markdown).html_safe
    render :show, formats: :html
  end

  private

  def chapters_with_availability
    Curriculum.all.map do |chapter|
      file_path = DOCS_PATH.join("#{chapter[:slug]}.md")
      chapter.merge(
        available: File.exist?(file_path),
        accessible: DocPolicy.new(current_user, chapter).view?
      )
    end
  end

  def chapters_by_phase(chapters)
    Curriculum.phases.map do |phase|
      phase_chapters = chapters.select { |chapter| phase[:range].cover?(chapter[:id].to_i) }
      available_count = phase_chapters.count { |chapter| chapter[:available] }

      phase.merge(
        chapters: phase_chapters,
        available_count: available_count,
        total_count: phase_chapters.size
      )
    end
  end
end
