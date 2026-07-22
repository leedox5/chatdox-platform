require "test_helper"

class AdminDbBackupTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(name: "테스트 유저", email: "db-backup-admin@example.com", password: "password123", role: :admin)
    @other = User.create!(name: "테스트 유저", email: "db-backup-other@example.com", password: "password123")
    @previous_database_url = ENV["DATABASE_URL"]
  end

  teardown do
    if @previous_database_url.nil?
      ENV.delete("DATABASE_URL")
    else
      ENV["DATABASE_URL"] = @previous_database_url
    end
  end

  test "requires admin authentication" do
    post admin_db_backup_path
    assert_redirected_to new_user_session_path

    sign_in(@other)
    post admin_db_backup_path
    assert_redirected_to root_path
  end

  test "redirects with a clear message when DATABASE_URL is not configured" do
    ENV.delete("DATABASE_URL")
    sign_in(@admin)

    post admin_db_backup_path

    assert_redirected_to admin_dashboard_path
    follow_redirect!
    assert_match(/DATABASE_URL/, response.body)
  end

  test "fails gracefully instead of crashing when pg_dump is not installed" do
    ENV["DATABASE_URL"] = "postgres://appuser:s3cret@db.internal:5432/chatdox_production"
    sign_in(@admin)

    # Simulate the binary being absent via Errno::ENOENT (a SystemCallError) --
    # this used to rely on pg_dump genuinely not being installed in this
    # dev/test environment, but that's no longer a safe assumption to make
    # about any given machine this suite runs on, so it's stubbed instead.
    fake_capture3 = lambda do |*_args, **_kwargs|
      raise Errno::ENOENT, "pg_dump"
    end

    with_singleton_method(Open3, :capture3, fake_capture3) do
      post admin_db_backup_path
    end

    assert_redirected_to admin_dashboard_path
    follow_redirect!
    assert_match(/pg_dump/, response.body)
  end

  test "connects via PG* env vars, not by passing the URL as a command-line argument, and never logs it" do
    ENV["DATABASE_URL"] = "postgres://appuser:s3cr%2Bet@db.internal:5432/chatdox_production"
    sign_in(@admin)

    captured_env = nil
    captured_argv = nil
    fake_capture3 = lambda do |*args, **_kwargs|
      captured_env = args.first
      captured_argv = args[1..]
      [ "FAKE-DUMP-BYTES", "", Struct.new(:success?, :exitstatus).new(true, 0) ]
    end

    with_singleton_method(Open3, :capture3, fake_capture3) do
      post admin_db_backup_path
    end

    assert_response :success
    assert_equal "FAKE-DUMP-BYTES", response.body

    assert_equal %w[pg_dump -Fc -d chatdox_production], captured_argv
    assert_not captured_argv.any? { |arg| arg.include?("s3cr+et") || arg.include?("appuser") }
    assert_equal "db.internal", captured_env["PGHOST"]
    assert_equal "5432", captured_env["PGPORT"]
    assert_equal "appuser", captured_env["PGUSER"]
    assert_equal "s3cr+et", captured_env["PGPASSWORD"]
  end

  test "logs pg_dump's stderr with the password redacted when it fails, so the real cause is diagnosable" do
    ENV["DATABASE_URL"] = "postgres://appuser:s3cr%2Bet@db.internal:5432/chatdox_production"
    sign_in(@admin)

    fake_stderr = 'pg_dump: error: connection to server failed: FATAL: password authentication failed for user "appuser" (using password: s3cr+et)'
    fake_capture3 = lambda do |*_args, **_kwargs|
      [ "", fake_stderr, Struct.new(:success?, :exitstatus).new(false, 1) ]
    end

    logged = capture_logger_errors do
      with_singleton_method(Open3, :capture3, fake_capture3) do
        post admin_db_backup_path
      end
    end

    assert_redirected_to admin_dashboard_path
    combined = logged.join("\n")
    assert_match(/pg_dump exited with status 1/, combined)
    assert_match(/connection to server failed/, combined)
    assert_match(/authentication failed for user "appuser"/, combined)
    assert_match(/\[REDACTED\]/, combined)
    assert_no_match(/s3cr\+et/, combined)
  end

  test "does not corrupt the logged stderr when the password happens to be blank" do
    ENV["DATABASE_URL"] = "postgres://appuser@db.internal:5432/chatdox_production"
    sign_in(@admin)

    fake_stderr = "pg_dump: error: something unrelated went wrong"
    fake_capture3 = lambda do |*_args, **_kwargs|
      [ "", fake_stderr, Struct.new(:success?, :exitstatus).new(false, 1) ]
    end

    logged = capture_logger_errors do
      with_singleton_method(Open3, :capture3, fake_capture3) do
        post admin_db_backup_path
      end
    end

    assert_match(/something unrelated went wrong/, logged.join("\n"))
  end

  private

  def sign_in(user)
    post user_session_path, params: { user: { email: user.email, password: "password123" } }
  end

  def with_singleton_method(object, method_name, replacement)
    original = object.method(method_name)
    object.define_singleton_method(method_name, replacement)
    yield
  ensure
    object.define_singleton_method(method_name, original)
  end

  def capture_logger_errors
    logged = []
    original_error = Rails.logger.method(:error)
    Rails.logger.define_singleton_method(:error) { |msg| logged << msg }
    yield
    logged
  ensure
    Rails.logger.define_singleton_method(:error, original_error)
  end
end
