class Admin::ContentProgressController < Admin::BaseController
  CHATDOX_PATH = Rails.root.join("hq/chatdox")
  CLAUDOX_PATH = Rails.root.join("hq/claudox")
  CLAUDOX_PROGRESS_PATH = CLAUDOX_PATH.join("88_progress.md")
  CLAUDOX_ROW_PATTERN = /^\|\s*\d+\s*\|\s*(.+?)\s*\|\s*\[.+?\]\((\d{2}_[a-z0-9_]+)\.md\)\s*\|\s*(\d+)%\s*\|\s*(✅|⬜)\s*\|$/

  def show
    @chatdox_chapters = Curriculum.all.map do |chapter|
      chapter.merge(written: File.exist?(CHATDOX_PATH.join("#{chapter[:slug]}.md")))
    end
    @chatdox_written_count = @chatdox_chapters.count { |chapter| chapter[:written] }

    @claudox_chapters = parse_claudox_progress
    @claudox_done_count = @claudox_chapters.count { |chapter| chapter[:done] }
  end

  private

  def parse_claudox_progress
    return [] unless File.exist?(CLAUDOX_PROGRESS_PATH)

    File.read(CLAUDOX_PROGRESS_PATH).scan(CLAUDOX_ROW_PATTERN).map do |title, slug, percent, status|
      file_path = CLAUDOX_PATH.join("#{slug}.md")
      {
        id: slug[0, 2],
        title: title,
        percent: percent.to_i,
        done: status == "✅",
        updated_at: File.exist?(file_path) ? File.mtime(file_path) : nil
      }
    end
  end
end
