require "test_helper"

class ClaudoxPageCtaAndSampleTest < ActionDispatch::IntegrationTest
  test "hero has an immediate scroll-to-pricing CTA next to 읽기 시작하기" do
    get claudox_path
    assert_response :success

    doc = Nokogiri::HTML(response.body)
    hero = doc.at_css("h1").ancestors("section").first
    hero_links = hero.css("a")

    assert hero_links.any? { |link| link["href"] == claudox_read_path && link.text == "읽기 시작하기" }
    assert hero_links.any? { |link| link["href"] == "#pricing" }, "expected a hero button linking straight to the #pricing section"
  end

  test "no link in the page content points to Chatdox (the sitewide footer's cross-link is out of scope)" do
    get claudox_path
    assert_response :success

    doc = Nokogiri::HTML(response.body)
    main_content = doc.at_css("main")
    assert_empty main_content.css("a[href='#{chatdox_path}']")
    assert_no_match(/Chatdox 보기/, response.body)
    assert_no_match(/Cross Product/, response.body)
  end

  test "sample content is a single line item inside the included/excluded card, not its own section" do
    get claudox_path
    assert_response :success

    doc = Nokogiri::HTML(response.body)
    included_card = doc.css("article").find { |article| article.text.include?("포함 항목 / 미포함 항목") }
    assert included_card, "expected the 포함 항목 / 미포함 항목 card"
    assert_match(/샘플: 완성된 챕터 중 \d+개를 가입 없이 바로 읽어볼 수 있습니다/, included_card.text)

    sample_link = included_card.at_css("a")
    assert sample_link, "expected a single sample link inside the card"
    assert_equal "지금 읽어보기 →", sample_link.text
    assert_equal claudox_chapter_path("01"), sample_link["href"]

    # The old dedicated "샘플 콘텐츠" heading/section is gone.
    assert_no_match(/<h2[^>]*>샘플 콘텐츠<\/h2>/, response.body)
  end

  test "existing structure (chapters grid, FAQ, pricing section) is otherwise unaffected" do
    get claudox_path
    assert_response :success

    assert_match(/실제 구성과 목차/, response.body)
    assert_match(/FAQ/, response.body)
    assert_select "#pricing"
  end
end
