class DocsController < ApplicationController
  DOCS_PATH = Rails.root.join("docs/curriculum/docs")

  PHASES = [
    {
      key: "phase_1",
      label: "Phase 1",
      title: "기초 & 환경",
      description: "전체 구조 이해부터 프로젝트 구조 설계까지",
      range: 1..5
    },
    {
      key: "phase_2",
      label: "Phase 2",
      title: "핵심 기능 구현",
      description: "인증, 데이터, API, 결제, 운영 준비까지",
      range: 6..16
    },
    {
      key: "phase_3",
      label: "Phase 3",
      title: "프로덕션 운영",
      description: "모니터링, 보안, 성능 최적화, 런칭",
      range: 17..20
    }
  ].freeze

  CHAPTERS = [
    { id: "01", slug: "01_overview", title: "채독스 전체 구조 이해" },
    { id: "02", slug: "02_rails_basics", title: "Ruby on Rails 기초" },
    { id: "03", slug: "03_dev_setup", title: "개발 환경 세팅" },
    { id: "04", slug: "04_landing_page", title: "랜딩페이지 구축" },
    { id: "05", slug: "05_project_structure", title: "프로젝트 구조 설계" },
    { id: "06", slug: "06_database", title: "Database & Migrations" },
    { id: "07", slug: "07_authentication", title: "Authentication (Devise)" },
    { id: "08", slug: "08_authorization", title: "Authorization & 권한 관리" },
    { id: "09", slug: "09_payment", title: "Payment (Stripe)" },
    { id: "10", slug: "10_dashboard", title: "사용자 대시보드" },
    { id: "11", slug: "11_admin", title: "관리자 대시보드" },
    { id: "12", slug: "12_email", title: "Email & 알림" },
    { id: "13", slug: "13_file_upload", title: "파일 업로드 (Active Storage)" },
    { id: "14", slug: "14_api", title: "API 설계 & JSON" },
    { id: "15", slug: "15_testing", title: "테스트 (RSpec)" },
    { id: "16", slug: "16_performance", title: "성능 최적화 & 캐싱" },
    { id: "17", slug: "17_security", title: "보안 & OWASP" },
    { id: "18", slug: "18_deployment", title: "배포 (Railway / Render)" },
    { id: "19", slug: "19_monitoring", title: "모니터링 & 에러 추적" },
    { id: "20", slug: "20_launch", title: "런칭 & 운영" }
  ].freeze

  def index
    @chapters = chapters_with_availability
    @phase_chapters = chapters_by_phase(@chapters)
  end

  def show
    request.format = :html

    @chapters = chapters_with_availability
    @phase_chapters = chapters_by_phase(@chapters)
    @current_id = params[:id]
    @current_chapter = CHAPTERS.find { |chapter| chapter[:id] == @current_id }

    unless @current_chapter
      render plain: "챕터를 찾을 수 없습니다.", status: :not_found
      return
    end

    file_path = DOCS_PATH.join("#{@current_chapter[:slug]}.md")
    unless File.exist?(file_path)
      render plain: "아직 공개되지 않은 챕터입니다.", status: :not_found
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

  private

  def chapters_with_availability
    CHAPTERS.map do |chapter|
      file_path = DOCS_PATH.join("#{chapter[:slug]}.md")
      chapter.merge(available: File.exist?(file_path))
    end
  end

  def chapters_by_phase(chapters)
    PHASES.map do |phase|
      phase_chapters = chapters.select { |chapter| phase[:range].cover?(chapter[:id].to_i) }
      available_count = phase_chapters.count { |chapter| chapter[:available] }

      phase.merge(
        chapters: phase_chapters,
        available_count: available_count,
        total_count: phase_chapters.size
      )
    end
  end
end
