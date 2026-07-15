class Claudox
  PHASES = [
    {
      key: "part_1",
      label: "Part 1",
      title: "입문",
      description: "관계 맺기와 기본 협업 규칙 — Claudox와 처음 만나 이름을 정하고, 작업 규칙과 기억 체계를 세우는 단계.",
      range: 1..8
    },
    {
      key: "part_2",
      label: "Part 2",
      title: "중급",
      description: "실제 개발 워크플로우 — 폴더 구조부터 코드 리뷰, 테스트, Git/PR까지 엔지니어링 작업을 함께 처리하는 단계.",
      range: 9..15
    },
    {
      key: "part_3",
      label: "Part 3",
      title: "고급",
      description: "규모 확장과 메타적 자동화 — 서브에이전트와 워크플로우로 범위를 넓히고, 보안까지 챙기는 단계.",
      range: 16..20
    }
  ].freeze

  def self.phases
    PHASES
  end
end
