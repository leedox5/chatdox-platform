class ServiceDeskController < ApplicationController
  SERVICE_DESK_PATH = Rails.root.join("hq/service-desk")
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
    current_index = @requests.index { |request| request[:id] == params[:id].to_s }
    @current_request = current_index && @requests[current_index]

    unless @current_request
      render plain: "요청을 찾을 수 없거나 공개되지 않았습니다.", status: :not_found
      return
    end

    @prev_request = current_index.positive? ? @requests[current_index - 1] : nil
    @next_request = @requests[current_index + 1]

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
      markdown.render(normalize_request_markdown(raw_markdown)),
      tags: %w[
        h1 h2 h3 h4 h5 h6 p br hr ul ol li pre code blockquote strong em a
        table thead tbody tr th td
      ],
      attributes: %w[href target rel]
    )
  end

  # Every request file opens with a ```text ID/Date/.../Visibility block that
  # duplicates the styled summary cards the view already renders from
  # extract_request_metadata, so drop it here rather than show it twice.
  def strip_metadata_header(markdown)
    markdown.sub(/\A﻿?\s*```[^\n]*\n.*?\n```\s*\n?/m, "")
  end

  # Request files write a label line ("Description :", "Job :") directly
  # above a ```text fence with no blank line between them. Redcarpet only
  # recognizes a fenced block as interrupting a paragraph when preceded by a
  # blank line, so without one the ``` text ends up swallowed as literal
  # paragraph text and throws off every fence after it. Insert the blank line
  # the parser needs instead of relying on source files to include it.
  def ensure_blank_line_before_fences(markdown)
    lines = markdown.split("\n", -1)
    normalized = []
    lines.each do |line|
      if line.lstrip.start_with?("```") && normalized.any? && !normalized.last.strip.empty?
        normalized << ""
      end
      normalized << line
    end
    normalized.join("\n")
  end

  def normalize_request_markdown(raw_markdown)
    ensure_blank_line_before_fences(strip_metadata_header(raw_markdown))
  end
end