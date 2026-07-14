# One-time import of the git-based service-desk requests approved for DB
# migration (leedox_service_desk_db_r1). Source files under hq/service-desk/
# are read-only and never written back to — this only ever reads them.
namespace :service_desk do
  MIGRATION_TARGET_IDS = %w[
    0001 0003 0004 0005 0006 0008 0009 0010 0011 0012 0013 0017 0018 0019 0020
  ].freeze

  STATUS_BY_LABEL = {
    "New" => "pending",
    "In Progress" => "in_progress",
    "Completed" => "completed",
    "Confirmed" => "confirmed"
  }.freeze

  VISIBILITY_BY_LABEL = {
    "Public" => "visible",
    "Private" => "restricted"
  }.freeze

  desc "Import the 14 approved git-based service-desk requests into the DB-backed service desk"
  task import: :environment do
    source_dir = Rails.root.join("hq/service-desk")
    imported = 0

    MIGRATION_TARGET_IDS.each do |id|
      file_path = source_dir.join("#{id}.md")
      raise "Missing source file: #{file_path}" unless File.exist?(file_path)

      parsed = ServiceDeskRequestParser.parse(File.read(file_path))

      request = ServiceDeskRequest.find_or_initialize_by(request_number: parsed.id.to_i)
      request.assign_attributes(
        date: parsed.date,
        requester: parsed.requester,
        subject: parsed.subject,
        status: STATUS_BY_LABEL.fetch(parsed.status) { raise "Unknown status label: #{parsed.status.inspect} (#{id})" },
        visibility: VISIBILITY_BY_LABEL.fetch(parsed.visibility) { raise "Unknown visibility label: #{parsed.visibility.inspect} (#{id})" },
        description: parsed.description
      )
      request.save!

      parsed.jobs.each do |job|
        record = request.service_desk_jobs.find_or_initialize_by(job_number: job.job_number)
        record.assign_attributes(author: job.author, performed_at: job.performed_at, content: job.content)
        record.save!
      end

      imported += 1
      puts "Imported #{id} (#{parsed.jobs.size} jobs)"
    end

    puts "Done. #{imported}/#{MIGRATION_TARGET_IDS.size} requests imported. " \
         "DB now has #{ServiceDeskRequest.count} requests, #{ServiceDeskJob.count} jobs."
  end

  desc "Verify DB-imported requests match their original hq/service-desk/*.md source files field-for-field"
  task verify_import: :environment do
    source_dir = Rails.root.join("hq/service-desk")
    mismatches = []

    MIGRATION_TARGET_IDS.each do |id|
      parsed = ServiceDeskRequestParser.parse(File.read(source_dir.join("#{id}.md")))
      request = ServiceDeskRequest.find_by(request_number: id.to_i)

      if request.nil?
        mismatches << "#{id}: missing from DB"
        next
      end

      mismatches << "#{id}: date #{request.date} != #{parsed.date}" unless request.date == parsed.date
      mismatches << "#{id}: requester #{request.requester.inspect} != #{parsed.requester.inspect}" unless request.requester == parsed.requester
      mismatches << "#{id}: subject #{request.subject.inspect} != #{parsed.subject.inspect}" unless request.subject == parsed.subject
      mismatches << "#{id}: status #{request.status_label.inspect} != #{parsed.status.inspect}" unless request.status_label == parsed.status
      mismatches << "#{id}: visibility #{request.visibility_label.inspect} != #{parsed.visibility.inspect}" unless request.visibility_label == parsed.visibility
      mismatches << "#{id}: description mismatch" unless request.description.to_s == parsed.description.to_s

      db_jobs = request.service_desk_jobs.order(:job_number)
      mismatches << "#{id}: job count #{db_jobs.size} != #{parsed.jobs.size}" unless db_jobs.size == parsed.jobs.size
      parsed.jobs.zip(db_jobs).each do |expected, actual|
        next if expected.nil? || actual.nil?

        mismatches << "#{id}: job #{expected.job_number} author #{actual.author.inspect} != #{expected.author.inspect}" unless actual.author == expected.author
        mismatches << "#{id}: job #{expected.job_number} performed_at #{actual.performed_at} != #{expected.performed_at}" unless actual.performed_at == expected.performed_at
        mismatches << "#{id}: job #{expected.job_number} content mismatch" unless actual.content.to_s == expected.content.to_s
      end
    end

    (ServiceDeskRequest.pluck(:request_number).map { |n| n.to_s.rjust(4, "0") } - MIGRATION_TARGET_IDS).each do |extra|
      mismatches << "#{extra}: present in DB but not in migration target list"
    end

    if mismatches.empty?
      puts "OK — all #{MIGRATION_TARGET_IDS.size} requests match their source files field-for-field."
    else
      puts "MISMATCHES FOUND:"
      mismatches.each { |m| puts "  - #{m}" }
      exit 1
    end
  end
end
