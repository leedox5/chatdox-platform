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

    progress_source = File.read(Rails.root.join("hq/claudox/88_progress.md"))
    completed_line = progress_source.lines.find { |line| line.include?("완료(") }
    assert response.body.include?(completed_line.strip.delete("*")), "expected the Claudox progress summary line in the rendered output"
    assert_select "table"
  end

  test "admin dashboard links to the content progress page" do
    admin = User.create!(name: "테스트 유저", email: "content-progress-dash-admin@example.com", password: "password123", role: :admin)
    post user_session_path, params: { user: { email: admin.email, password: "password123" } }

    get admin_dashboard_path

    assert_response :success
    assert_select "a[href=?]", admin_content_progress_path, text: "콘텐츠 진행 현황"
  end
end
