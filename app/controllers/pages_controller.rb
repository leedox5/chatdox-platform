class PagesController < ApplicationController
  def home
    # Static landing page: no database query required.
  end

  def getting_started; end

  def pricing; end

  def community; end

  def login; end

  def terms; end

  def privacy; end

  PAYMENT_DOCS_PATH = Rails.root.join("public/docs/payment")

  PAYMENT_SECTIONS = [
    { id: "00", slug: "00_overview", title: "토스페이먼츠 결제 시스템" },
    { id: "01", slug: "01_setup", title: "환경 설정" },
    { id: "02", slug: "02_implementation", title: "구현 상세" },
    { id: "03", slug: "03_troubleshooting", title: "문제 해결" },
    { id: "04", slug: "04_testing", title: "테스트 결과" }
  ].freeze

  def payment_docs
    unless current_user&.admin?
      redirect_to root_path, alert: "권한이 없습니다."
      return
    end

    section_slug = params[:section]

    if section_slug.blank?
      @payment_sections = PAYMENT_SECTIONS
      render :payment_docs_index
      return
    end

    @current_section = PAYMENT_SECTIONS.find { |s| s[:slug] == section_slug }
    unless @current_section
      redirect_to admin_payment_docs_path, alert: "섹션을 찾을 수 없습니다."
      return
    end

    doc_path = PAYMENT_DOCS_PATH.join("#{section_slug}.md")
    unless File.exist?(doc_path)
      redirect_to admin_payment_docs_path, alert: "문서를 찾을 수 없습니다."
      return
    end

    raw_markdown = File.read(doc_path)
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
    @all_sections = PAYMENT_SECTIONS
    @current_index = @all_sections.find_index { |s| s[:slug] == section_slug }
    @prev_section = @current_index&.positive? ? @all_sections[@current_index - 1] : nil
    @next_section = @current_index && @current_index < @all_sections.length - 1 ? @all_sections[@current_index + 1] : nil

    render :payment_docs_show
  end
end
