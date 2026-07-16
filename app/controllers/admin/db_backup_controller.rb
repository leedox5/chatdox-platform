require "open3"
require "cgi"

# Manual snapshot of the production Postgres database, same philosophy as
# ServiceDeskExport: no scheduler, no cloud storage, just a button an admin
# clicks to get a file right now. Stopgap until Railway's Hobby plan (no
# automatic backups/PITR) is upgraded or replaced.
class Admin::DbBackupController < Admin::BaseController
  class PgDumpError < StandardError; end

  def download
    database_url = ENV.fetch("DATABASE_URL", nil)
    if database_url.blank?
      redirect_to admin_dashboard_path, alert: "DATABASE_URL이 설정되어 있지 않습니다."
      return
    end

    dump = run_pg_dump(database_url)
    filename = "chatdox-backup-#{Time.current.strftime('%Y%m%d-%H%M')}.dump"
    send_data dump, filename: filename, type: "application/octet-stream", disposition: "attachment"
  rescue SystemCallError
    Rails.logger.error("DB backup failed: pg_dump binary not found or not executable")
    redirect_to admin_dashboard_path, alert: "pg_dump 실행 파일을 찾을 수 없습니다. 서버 환경을 확인해 주세요."
  rescue PgDumpError => e
    Rails.logger.error("DB backup failed: #{e.message}")
    redirect_to admin_dashboard_path, alert: "백업 생성에 실패했습니다. 관리자 로그를 확인해 주세요."
  end

  private

  # Connection details go to pg_dump via PG* env vars, not as a URL argument --
  # command-line args are visible to any user on the host via `ps`, while env
  # vars passed to a specific subprocess are contained to that process (only
  # readable via /proc/<pid>/environ with matching privileges). Never log the
  # parsed URL, the env hash, or raw stderr (which can itself echo connection
  # details on some failure modes) -- only fixed, generic messages above.
  def run_pg_dump(database_url)
    uri = URI.parse(database_url)
    env = {
      "PGHOST" => uri.host.to_s,
      "PGPORT" => (uri.port || 5432).to_s,
      "PGUSER" => CGI.unescape(uri.user.to_s),
      "PGPASSWORD" => CGI.unescape(uri.password.to_s),
      "PGCONNECT_TIMEOUT" => "10"
    }
    dbname = uri.path.delete_prefix("/")

    stdout, _stderr, status = Open3.capture3(env, "pg_dump", "-Fc", "-d", dbname, binmode: true)
    raise PgDumpError, "pg_dump exited with status #{status.exitstatus}" unless status.success?

    stdout
  end
end
