module ChapterImages
  extend ActiveSupport::Concern

  private

  # Resolves filename against images_dir and refuses to serve anything that
  # escapes it (../, absolute paths, etc.) -- this route is public/unauthenticated.
  def serve_chapter_image(images_dir, filename)
    images_dir = images_dir.expand_path
    path = images_dir.join(filename).expand_path

    if path.to_s.start_with?("#{images_dir}/") && File.file?(path)
      send_file path, disposition: "inline"
    else
      head :not_found
    end
  rescue ArgumentError
    head :not_found
  end
end
