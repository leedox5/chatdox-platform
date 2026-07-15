require "test_helper"
require "stringio"

class CommerceEventLoggerTest < ActiveSupport::TestCase
  test "structured event contains only approved operational fields" do
    output = StringIO.new
    previous_logger = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(output)

    Commerce::EventLogger.log(
      event: "commerce.order_finalization_failed",
      provider: "toss",
      status: "pending",
      at: Time.utc(2026, 7, 15, 0, 0, 0)
    )

    log = output.string
    assert_match(/event=commerce\.order_finalization_failed/, log)
    assert_match(/provider=toss/, log)
    assert_match(/order_id=-/, log)
    assert_match(/status=pending/, log)
    assert_match(/occurred_at=2026-07-15T00:00:00Z/, log)
    assert_no_match(/payload|email|secret|card/, log)
  ensure
    Rails.logger = previous_logger
  end
end
