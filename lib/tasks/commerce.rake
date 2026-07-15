namespace :commerce do
  desc "Read-only release preflight (set PROVIDER=toss or PROVIDER=portone)"
  task preflight: :environment do
    provider = ENV.fetch("PROVIDER", ENV.fetch("PAYMENT_PROVIDER", "toss"))
    report = Commerce::ReleasePreflight.call(provider: provider)
    puts "commerce_preflight provider=#{provider} checked_at=#{report.checked_at.utc.iso8601} ready=#{report.ready_for_sandbox?}"
    report.checks.each do |check|
      puts "check=#{check.name} status=#{check.status} detail=#{check.detail}"
    end
  end

  desc "Read-only Order, PaymentTransaction, and License reconciliation"
  task reconcile: :environment do
    stale_minutes = Integer(ENV.fetch("STALE_AFTER_MINUTES", "30"), 10)
    report = Commerce::Reconciliation.call(stale_after: stale_minutes.minutes)
    puts "commerce_reconciliation checked_at=#{report.checked_at.utc.iso8601} status=#{report.ok? ? 'ok' : 'anomaly'} issues=#{report.issues.size}"
    report.issues.each do |issue|
      puts "issue=#{issue.code} provider=#{issue.provider} order_id=#{issue.order_public_id} status=#{issue.status}"
    end
  end
end
