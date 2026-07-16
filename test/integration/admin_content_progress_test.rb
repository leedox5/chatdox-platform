require "test_helper"

class AdminContentProgressTest < ActionDispatch::IntegrationTest
  test "guests and non-admins are blocked, admins see accurate Chatdox and Claudox progress" do
    user = User.create!(name: "테스트 유저", email: "content-progress-user@example.com", password: "password123")
    admin = User.create!(name: "테스트 유저", email: "content-progress-admin@example.com", password: "password123", role: :admin)

    get admin_content_progress_path
    assert_redirected_to new_user_session_path

    post user_session_path, params: { user: { email: user.email, password: "password123" } }
    get admin_content_progress_path
    assert_redirected_to root_path
    delete destroy_user_session_path

    post user_session_path, params: { user: { email: admin.email, password: "password123" } }
    get admin_content_progress_path
    assert_response :success

    written_count = Curriculum.all.count { |chapter| File.exist?(Rails.root.join("hq/chatdox/#{chapter[:slug]}.md")) }
    assert_match(/#{written_count}\s*\/\s*20/, response.body)

    doc = Nokogiri::HTML(response.body)
    Curriculum.all.each do |chapter|
      written = File.exist?(Rails.root.join("hq/chatdox/#{chapter[:slug]}.md"))
      row = doc.css("li").find { |li| li.text.include?(chapter[:title]) }
      assert row, "expected a row for #{chapter[:title]}"
      assert_equal written, row.text.include?("✅")
    end

    row_pattern = Admin::ContentProgressController::CLAUDOX_ROW_PATTERN
    progress_source = File.read(Rails.root.join("hq/claudox/88_progress.md"))
    claudox_rows = progress_source.scan(row_pattern)
    assert_equal 20, claudox_rows.size
    done_count = claudox_rows.count { |_title, _slug, _percent, status| status == "✅" }
    assert_match(/#{done_count}\s*\/\s*20/, response.body)

    claudox_rows.each do |title, slug, percent, status|
      id = slug[0, 2]
      row = doc.css("table tbody tr").find { |tr| tr.text.include?(title) }
      assert row, "expected a Claudox row for #{title}"

      link = row.at_css("a")
      assert_equal title, link.text
      assert_equal claudox_chapter_path(id), link["href"]
      assert_equal "#{percent}%", row.css("td")[2].text.strip
      assert_equal(status == "✅", row.css("td")[3].text.include?("✅"))
    end
  end

  test "admin dashboard links to the content progress page" do
    admin = User.create!(name: "테스트 유저", email: "content-progress-dash-admin@example.com", password: "password123", role: :admin)
    post user_session_path, params: { user: { email: admin.email, password: "password123" } }

    get admin_dashboard_path

    assert_response :success
    assert_select "a[href=?]", admin_content_progress_path, text: "콘텐츠 진행 현황"
  end
end
