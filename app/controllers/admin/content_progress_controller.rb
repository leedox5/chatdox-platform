class Admin::ContentProgressController < Admin::BaseController
  CHATDOX_PATH = Rails.root.join("hq/chatdox")
  CLAUDOX_PROGRESS_PATH = Rails.root.join("hq/claudox/88_progress.md")

  def show
    @chatdox_chapters = Curriculum.all.map do |chapter|
      chapter.merge(written: File.exist?(CHATDOX_PATH.join("#{chapter[:slug]}.md")))
    end
    @chatdox_written_count = @chatdox_chapters.count { |chapter| chapter[:written] }

    @claudox_progress_html = MarkdownRenderer.render(File.read(CLAUDOX_PROGRESS_PATH)) if File.exist?(CLAUDOX_PROGRESS_PATH)
  end
end
