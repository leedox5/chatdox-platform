require "test_helper"

class ExternalAccessReconciliationTest < ActiveSupport::TestCase
  KST = License::KST

  setup do
    Commerce::CatalogBootstrap.call!
    @product = Product.find_by!(code: "chatdox")
    @at = KST.local(2026, 7, 15, 12)
    @sequence = 0
  end

  test "a synchronized external grant and task produce no github reconciliation issues and remain read only" do
    user = create_user
    create_license(user: user, active: true)
    create_verified_link(user)
    ExternalAccess::DueProcessor.call!(at: @at)
    before = external_snapshot

    report = Commerce::Reconciliation.call(at: @at, log: false)

    assert_empty report.issues.select { |issue| issue.provider == "github" }
    assert_equal before, external_snapshot
  end

  test "reconciliation detects missing expired overdue inactive and mismatched external access read only" do
    missing_user = create_user
    create_license(user: missing_user, active: true)
    create_verified_link(missing_user)

    invited = create_grant(status: "invited", license_active: true)
    invited.update_columns(invited_at: @at - 8.days)

    expired = create_grant(status: "active", license_active: false)

    overdue = create_grant(status: "revoke_due", license_active: false)
    overdue.update_columns(revoke_due_at: @at - 2.days)

    revoked = create_grant(status: "revoked", license_active: false)
    ExternalAccess::TaskFactory.ensure!(
      task_type: "confirm_revocation", link: revoked.external_account_link,
      grant: revoked, due_at: @at - 1.day
    )

    inactive = create_grant(status: "grant_due", license_active: true)
    inactive.external_account_link.update!(status: "change_requested", change_requested_at: @at)

    mismatched = create_grant(status: "active", license_active: true)
    ExternalAccess::TaskFactory.ensure!(
      task_type: "send_invite", link: mismatched.external_account_link,
      grant: mismatched, due_at: @at
    )

    before = external_snapshot
    report = Commerce::Reconciliation.call(at: @at, log: false)
    codes = report.issues.select { |issue| issue.provider == "github" }.map(&:code)

    %w[
      active_license_verified_link_missing_grant invited_acceptance_overdue
      expired_license_live_grant revoke_due_overdue revoked_grant_open_revoke_task
      live_grant_inactive_link task_grant_state_mismatch
    ].each { |code| assert_includes codes, code }
    assert_equal before, external_snapshot
    assert expired.persisted?
  end

  test "reconciliation reports duplicate identities and active grants when database constraints are bypassed" do
    grant = create_grant(status: "active", license_active: true)
    link = grant.external_account_link
    duplicate_relation = fake_grouped_relation({ [ "github", "duplicate" ] => 2 }, first: link)
    duplicate_grants = fake_grouped_relation({ [ grant.user_id, grant.product_id ] => 2 }, first: grant)
    original_available = ExternalAccountLink.method(:available)
    original_where = ExternalAccessGrant.method(:where)

    ExternalAccountLink.define_singleton_method(:available) { duplicate_relation }
    ExternalAccessGrant.define_singleton_method(:where) do |*args|
      args == [ { status: "active" } ] ? duplicate_grants : original_where.call(*args)
    end

    report = Commerce::Reconciliation.call(at: @at, log: false)
    codes = report.issues.map(&:code)

    assert_includes codes, "duplicate_github_identity"
    assert_includes codes, "multiple_active_product_grants"
  ensure
    ExternalAccountLink.define_singleton_method(:available, original_available) if original_available
    ExternalAccessGrant.define_singleton_method(:where, original_where) if original_where
  end

  private

  def create_user
    @sequence += 1
    User.create!(email: "external-reconcile-#{@sequence}@example.com", password: "password123", created_at: 30.days.ago)
  end

  def create_verified_link(user)
    @sequence += 1
    ExternalAccountLink.create!(
      user: user, provider: "github", username: "reconcile-#{@sequence}",
      external_uid: (10_000 + @sequence).to_s, status: "verified", verified_at: @at
    )
  end

  def create_license(user:, active:)
    start_on = active ? @at.to_date : @at.to_date - 2.months
    last_on = start_on + 1.month - 1.day
    License.create!(
      user: user, product: @product, source: "paid", status: "active",
      starts_on: start_on, last_usable_on: last_on,
      access_ends_at: KST.local((last_on + 1.day).year, (last_on + 1.day).month, (last_on + 1.day).day)
    )
  end

  def create_grant(status:, license_active:)
    user = create_user
    license = create_license(user: user, active: license_active)
    link = create_verified_link(user)
    grant = ExternalAccessGrant.create!(
      user: user, product: @product, license: license, external_account_link: link,
      repository_key: "chatdox_lab", status: "pending"
    )
    grant.update_columns(status: status)
    grant.reload
  end

  def external_snapshot
    [ ExternalAccountLink, ExternalAccessGrant, ExternalAccessTask, ExternalAccessEvent, License ].to_h do |model|
      [ model.name, [ model.count, model.order(:id).pluck(:id, :updated_at) ] ]
    end
  end

  def fake_grouped_relation(counts, first:)
    Object.new.tap do |relation|
      relation.define_singleton_method(:group) { |*| self }
      relation.define_singleton_method(:having) { |*| self }
      relation.define_singleton_method(:where) { |*| self }
      relation.define_singleton_method(:not) { |*| self }
      relation.define_singleton_method(:count) { counts }
      relation.define_singleton_method(:empty?) { counts.empty? }
      relation.define_singleton_method(:first) { first }
    end
  end
end
