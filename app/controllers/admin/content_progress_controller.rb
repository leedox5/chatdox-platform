class Admin::ContentProgressController < Admin::BaseController
  CHATDOX_PATH = Rails.root.join("hq/chatdox")
  CLAUDOX_PROGRESS_PATH = Rails.root.join("hq/claudox/88_progress.md")

  def show
    @chatdox_chapters = Curriculum.all.map do |chapter|
      chapter.merge(written: File.exist?(CHATDOX_PATH.join("#{chapter[:slug]}.md")))
    end
    @chatdox_written_count = @chatdox_chapters.count { |chapter| chapter[:written] }

    if File.exist?(CLAUDOX_PROGRESS_PATH)
      @claudox_progress_html = MarkdownRenderer.render(linked_claudox_progress_source)
    end
  end

  private

  def linked_claudox_progress_source
    File.read(CLAUDOX_PROGRESS_PATH).gsub(/\]\((\d{2})_[a-z0-9_]+\.md\)/) { "](#{claudox_chapter_path($1)})" }
  end
end
