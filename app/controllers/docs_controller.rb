class DocsController < ApplicationController
  DOCS_PATH = Rails.root.join("docs/curriculum/docs")

  CHAPTERS = [
    {
      id: "01_overview",
      title: "채독스 전체 구조 이해",
      subtitle: "서비스 아키텍처, 기술 스택, 학습 로드맵"
    },
    {
      id: "02_rails_basics",
      title: "Ruby on Rails 기초",
      subtitle: "Rails 개념, MVC 패턴, 주요 기능"
    },
    {
      id: "03_dev_setup",
      title: "개발 환경 세팅",
      subtitle: "Git, 데이터베이스, 종속성 설치"
    },
    {
      id: "04_landing_page",
      title: "랜딩페이지 구축",
      subtitle: "Tailwind CSS, 반응형 디자인"
    }
  ].freeze

  def index
    @chapters = CHAPTERS
  end

  def show
    request.format = :html

    @chapters = CHAPTERS
    @current_id = params[:id]
    @current_chapter = CHAPTERS.find { |chapter| chapter[:id] == @current_id }

    unless @current_chapter
      render plain: "챕터를 찾을 수 없습니다.", status: :not_found
      return
    end

    file_path = DOCS_PATH.join("#{@current_id}.md")
    unless File.exist?(file_path)
      render plain: "파일을 찾을 수 없습니다: #{@current_id}.md", status: :not_found
      return
    end

    raw_markdown = File.read(file_path)

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
    render :show, formats: :html
  end
end
