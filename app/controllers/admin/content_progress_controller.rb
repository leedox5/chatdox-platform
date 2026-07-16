class Admin::ContentProgressController < Admin::BaseController
  CHATDOX_PATH = Rails.root.join("hq/chatdox")
  CLAUDOX_PATH = Rails.root.join("hq/claudox")
  CLAUDOX_PROGRESS_PATH = CLAUDOX_PATH.join("88_progress.md")
  CLAUDOX_ROW_PATTERN = /^\|\s*\d+\s*\|\s*(.+?)\s*\|\s*\[.+?\]\((\d{2})_[a-z0-9_]+\.md\)\s*\|\s*\d+%\s*\|\s*(✅|⬜)\s*\|$/

  def show
    @chatdox_chapters = Curriculum.all.map do |chapter|
      {
        id: chapter[:id],
        title: chapter[:title],
        done: File.exist?(CHATDOX_PATH.join("#{chapter[:slug]}.md")),
        path: doc_path(chapter[:id])
      }
    end
    @chatdox_done_count = @chatdox_chapters.count { |chapter| chapter[:done] }
    @chatdox_percent = percent(@chatdox_done_count, @chatdox_chapters.size)
    @chatdox_phases = group_by_phase(@chatdox_chapters, Curriculum.phases)

    @claudox_chapters = parse_claudox_progress
    @claudox_done_count = @claudox_chapters.count { |chapter| chapter[:done] }
    @claudox_percent = percent(@claudox_done_count, @claudox_chapters.size)
    @claudox_phases = group_by_phase(@claudox_chapters, Claudox.phases)
  end

  private

  def parse_claudox_progress
    return [] unless File.exist?(CLAUDOX_PROGRESS_PATH)

    File.read(CLAUDOX_PROGRESS_PATH).scan(CLAUDOX_ROW_PATTERN).map do |title, id, status|
      { id: id, title: title, done: status == "✅", path: claudox_chapter_path(id) }
    end
  end

  def group_by_phase(chapters, phases)
    phases.map do |phase|
      phase_chapters = chapters.select { |chapter| phase[:range].cover?(chapter[:id].to_i) }
      phase.merge(chapters: phase_chapters, done_count: phase_chapters.count { |chapter| chapter[:done] })
    end
  end

  def percent(done, total)
    return 0 if total.zero?

    ((done.to_f / total) * 100).round
  end
end
