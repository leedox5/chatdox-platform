class ClaudoxProductsController < ApplicationController
  CLAUDOX_PATH = Rails.root.join("docs/curriculum/claudox")
  CLAUDOX_SETUP_PATH = CLAUDOX_PATH.join("setup.md")
  UNWRITTEN_PLACEHOLDER = "*(아직 작성되지 않음)*"

  def show
    @chapters = setup_chapters.map do |chapter|
      chapter_file = chapter_file_for(chapter[:id])
      available = chapter_file.present?
      complete = available && chapter_written?(chapter_file)

      chapter.merge(
        available: available,
        complete: complete,
        slug: chapter_file ? File.basename(chapter_file, ".md") : nil,
        title: available ? extract_title(chapter_file) : chapter[:title]
      )
    end

    @featured_chapters = @chapters.select { |chapter| chapter[:complete] }.first(3)
  end

  private

  def setup_chapters
    return fallback_chapters unless File.exist?(CLAUDOX_SETUP_PATH)

    chapters = []
    File.foreach(CLAUDOX_SETUP_PATH) do |line|
      next unless (match = line.match(/^\s*(\d{1,2})\.\s+(.+)$/))

      chapters << {
        id: match[1].to_i.to_s.rjust(2, "0"),
        title: match[2].strip
      }
    end

    chapters.select { |chapter| (1..20).cover?(chapter[:id].to_i) }
  end

  def fallback_chapters
    (1..20).map { |id| { id: id.to_s.rjust(2, "0"), title: "Chapter #{id}" } }
  end

  def chapter_file_for(chapter_id)
    Dir.glob(CLAUDOX_PATH.join("#{chapter_id}_*.md")).sort.first
  end

  def extract_title(file_path)
    File.foreach(file_path) do |line|
      next unless line.start_with?("#")

      return line.sub(/^#+\s*/, "").strip
    end

    File.basename(file_path, ".md").tr("_", " ")
  end

  def chapter_written?(file_path)
    !File.read(file_path).include?(UNWRITTEN_PLACEHOLDER)
  end
end
