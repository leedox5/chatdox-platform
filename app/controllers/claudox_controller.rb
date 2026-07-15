class ClaudoxController < ApplicationController
  CLAUDOX_PATH = Rails.root.join("hq/claudox")

  def index
    @chapters = available_chapters
    @phase_chapters = chapters_by_phase(@chapters)
  end

  def show
    @chapters = available_chapters
    @phase_chapters = chapters_by_phase(@chapters)
    @current_id = params[:id].to_s.rjust(2, "0")
    @current_chapter = @chapters.find { |chapter| chapter[:id] == @current_id }

    unless @current_chapter&.dig(:available)
      render plain: "아직 공개되지 않은 챕터입니다.", status: :not_found
      return
    end

    authorize @current_chapter, :view?, policy_class: DocPolicy

    file_path = CLAUDOX_PATH.join("#{@current_chapter[:slug]}.md")
    @last_updated_at = File.mtime(file_path)
    raw_markdown = File.read(file_path)

    @content_html = render_markdown(strip_leading_heading(raw_markdown))
  end

  private

  def available_chapters
    Dir.glob(CLAUDOX_PATH.join("[0-9][0-9]_*.md")).sort.filter_map do |file_path|
      id = File.basename(file_path, ".md").split("_", 2).first
      next unless (1..20).cover?(id.to_i)

      chapter = {
        id: id,
        slug: File.basename(file_path, ".md"),
        title: extract_title(file_path),
        product_code: "claudox",
        available: true
      }

      chapter.merge(accessible: DocPolicy.new(current_user, chapter).view?)
    end
  end

  def chapters_by_phase(chapters)
    Claudox.phases.map do |phase|
      phase_chapters = chapters.select { |chapter| phase[:range].cover?(chapter[:id].to_i) }
      available_count = phase_chapters.count { |chapter| chapter[:available] }

      phase.merge(
        chapters: phase_chapters,
        available_count: available_count,
        total_count: phase_chapters.size
      )
    end
  end

  def extract_title(file_path)
    File.foreach(file_path) do |line|
      next unless line.start_with?("#")

      return line.sub(/^#+\s*/, "").strip
    end

    File.basename(file_path, ".md").tr("_", " ")
  end

  def strip_leading_heading(raw_markdown)
    raw_markdown.sub(/\A\s*#[^\n]*\n?/, "")
  end

  def render_markdown(raw_markdown)
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

    markdown.render(raw_markdown).html_safe
  end
end
