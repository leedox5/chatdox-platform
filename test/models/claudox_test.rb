require "test_helper"

class ClaudoxTest < ActiveSupport::TestCase
  test "all returns chapters sorted by id with titles extracted from the markdown heading" do
    chapters = Claudox.all

    assert_equal chapters.map { |c| c[:id] }, chapters.map { |c| c[:id] }.sort
    first = chapters.first
    assert_equal "01", first[:id]
    assert_equal "claudox", first[:product_code]
    assert first[:available]
    assert first[:title].present?
  end

  test "find looks up a single chapter by id, normalizing to a zero-padded two-digit id" do
    chapter = Claudox.find("1")

    assert_equal "01", chapter[:id]
    assert_equal Claudox.all.first[:title], chapter[:title]
  end

  test "find returns nil for a chapter number with no matching file" do
    assert_nil Claudox.find("99")
  end
end
