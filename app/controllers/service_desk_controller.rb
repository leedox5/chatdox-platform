class ServiceDeskController < ApplicationController
  SERVICE_DESK_PATH = Rails.root.join("service-desk")
  REQUESTS_PATH = SERVICE_DESK_PATH

  before_action :authenticate_user!
  before_action :authorize_service_desk!

  def index
    @requests = requests_for_index
    @current_request = selected_request(@requests)
    @last_updated_at = File.mtime(@current_request[:file_path])
    @content_html = render_markdown(File.read(@current_request[:file_path]))
  end

  def show
    @requests = requests_for_index
    @current_request = @requests.find { |request| request[:id] == params[:id].to_s }

    unless @current_request
      render plain: "요청을 찾을 수 없거나 공개되지 않았습니다.", status: :not_found
      return
    end

    @last_updated_at = File.mtime(@current_request[:file_path])
    @content_html = render_markdown(File.read(@current_request[:file_path]))
  end

  private

  def authorize_service_desk!
    authorize :admin, :access?
  end

  def requests_for_index
    Dir.glob(REQUESTS_PATH.join("[0-9][0-9][0-9][0-9].md")).sort.map do |file_path|
      extract_request_metadata(file_path).merge(file_path: file_path)
    end.reject { |request| request[:visibility].casecmp("Private").zero? }
  end

  def selected_request(requests)
    requests.find { |request| request[:id] == params[:id].to_s } || requests.first
  end

  def extract_request_metadata(file_path)
    contents = File.read(file_path)

    {
      id: read_request_field(contents, "ID") || File.basename(file_path, ".md"),
      date: read_request_field(contents, "Date"),
      requester: read_request_field(contents, "Requester"),
      subject: read_request_field(contents, "Subject") || File.basename(file_path, ".md"),
      status: read_request_field(contents, "Status") || "New",
      visibility: read_request_field(contents, "Visibility") || "Public"
    }
  end

  def read_request_field(contents, label)
    contents.each_line do |line|
      match = line.strip.match(/^#{Regexp.escape(label)}\s*:\s*(.+)$/)
      return match[1].strip if match
    end

    nil
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

    helpers.sanitize(
      markdown.render(raw_markdown),
      tags: %w[
        h1 h2 h3 h4 h5 h6 p br hr ul ol li pre code blockquote strong em a
        table thead tbody tr th td
      ],
      attributes: %w[href target rel]
    )
  end
end