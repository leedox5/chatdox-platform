require "test_helper"

class ExternalAccessOperationsTest < ActiveSupport::TestCase
  KST = License::KST

  setup do
    Commerce::CatalogBootstrap.call!
    @product = Product.find_by!(code: "chatdox")
    @user = User.create!(email: "external-user@example.com", password: "password123", created_at: 30.days.ago)
    @other = User.create!(email: "external-other@example.com", password: "password123", created_at: 30.days.ago)
    @admin = User.create!(email: "external-admin@example.com", password: "password123", role: :admin)
    @at = KST.local(2026, 7, 15, 12)
  end

  test "github username is normalized validated and unique across users" do
    link = ExternalAccess::LinkSubmission.call!(user: @user, username: "  @Octo-Cat ", at: @at)

    assert_equal "Octo-Cat", link.username
    assert_equal "octo-cat", link.normalized_username
    assert_equal "github", link.provider
    assert_equal "pending_verification", link.status
    assert_nil link.external_uid
    assert link.external_access_tasks.exists?(task_type: "verify_account", status: "pending")
    assert link.external_access_events.exists?(action: "link_requested", actor: @user)

    assert_raises(ActiveRecord::RecordInvalid) do
      ExternalAccess::LinkSubmission.call!(user: @other, username: "octo-cat", at: @at)
    end
    assert_raises(ActiveRecord::RecordInvalid) do
      ExternalAccess::LinkSubmission.call!(user: @other, username: "bad--name", at: @at)
    end
    link.update!(external_uid: "9000")
    assert_raises(ActiveRecord::RecordInvalid) do
      ExternalAccountLink.create!(
        user: @other, provider: "github", username: "different-name",
        external_uid: "9000", status: "verified"
      )
    end
  end

  test "verified links receive idempotent grant tasks only when the license starts" do
    scheduled = create_license(user: @user, starts_on: @at.to_date + 1.day)
    link = submitted_and_verified_link(@user, uid: "1001")

    assert_no_difference [ "ExternalAccessGrant.count", "ExternalAccessTask.count" ] do
      ExternalAccess::DueProcessor.call!(at: @at)
    end

    assert_difference "ExternalAccessGrant.count", 1 do
      ExternalAccess::DueProcessor.call!(at: scheduled.starts_at)
    end
    grant = link.external_access_grants.find_by!(license: scheduled)
    assert_equal "grant_due", grant.status
    assert grant.external_access_tasks.exists?(task_type: "send_invite", status: "pending")

    assert_no_difference [ "ExternalAccessGrant.count", "ExternalAccessTask.count" ] do
      2.times { ExternalAccess::DueProcessor.call!(at: scheduled.starts_at) }
    end
  end

  test "manual invite acceptance and expiry revocation preserve licenses and call no external API" do
    license = create_license(user: @user, starts_on: @at.to_date)
    link = submitted_and_verified_link(@user, uid: "1002")
    grant = link.external_access_grants.find_by!(license: license)

    complete_task(grant, "send_invite", at: @at)
    assert_equal "invited", grant.reload.status
    complete_task(grant, "confirm_acceptance", at: @at + 1.minute)
    assert_equal "active", grant.reload.status

    counts = [ License.count, Order.count, PaymentTransaction.count ]
    result = ExternalAccess::DueProcessor.call!(at: license.access_ends_at)
    assert_equal 1, result.revokes_marked
    assert_equal "revoke_due", grant.reload.status

    complete_task(grant, "revoke_access", at: license.access_ends_at + 1.minute)
    complete_task(grant, "confirm_revocation", at: license.access_ends_at + 2.minutes)
    assert_equal "revoked", grant.reload.status
    assert_equal counts, [ License.count, Order.count, PaymentTransaction.count ]
    assert grant.external_access_events.exists?(action: "grant_invited", actor: @admin)
    assert grant.external_access_events.exists?(action: "grant_activated", actor: @admin)
    assert grant.external_access_events.exists?(action: "grant_revoked", actor: @admin)
  end

  test "invite and acceptance cannot create active access without a current license" do
    license = create_license(user: @user, starts_on: @at.to_date + 1.day)
    link = submitted_and_verified_link(@user, uid: "1003")
    grant = ExternalAccessGrant.create!(
      user: @user, product: @product, license: license, external_account_link: link,
      status: "grant_due", repository_key: "chatdox_lab"
    )
    task = ExternalAccess::TaskFactory.ensure!(task_type: "send_invite", link: link, grant: grant, due_at: @at)

    assert_raises(ActiveRecord::RecordInvalid) do
      ExternalAccess::TaskProcessor.call!(task: task, actor: @admin, action: "complete", at: @at)
    end
    assert_equal "grant_due", grant.reload.status
    assert_equal "pending", task.reload.status
  end

  test "account replacement requires old revocation before new verification and grant" do
    license = create_license(user: @user, starts_on: @at.to_date)
    old_link = submitted_and_verified_link(@user, uid: "2001")
    old_grant = old_link.external_access_grants.find_by!(license: license)
    complete_task(old_grant, "send_invite", at: @at)
    complete_task(old_grant, "confirm_acceptance", at: @at + 1.minute)

    replacement = ExternalAccess::AccountChangeRequest.call!(
      user: @user, current_link: old_link, username: "replacement-user", at: @at + 2.minutes
    )
    change_task = replacement.external_access_tasks.find_by!(task_type: "process_account_change")
    ExternalAccess::TaskProcessor.call!(
      task: change_task, actor: @admin, action: "complete", external_uid: "2002", at: @at + 3.minutes
    )
    assert_equal "revoke_due", old_grant.reload.status
    assert_not replacement.external_access_tasks.exists?(task_type: "verify_account", status: "pending")

    forged_verify = ExternalAccess::TaskFactory.ensure!(task_type: "verify_account", link: replacement, due_at: @at + 3.minutes)
    assert_raises(ExternalAccess::TaskProcessor::InvalidAction) do
      ExternalAccess::TaskProcessor.call!(task: forged_verify, actor: @admin, action: "complete", external_uid: "2002", at: @at + 3.minutes)
    end

    complete_task(old_grant, "revoke_access", at: @at + 4.minutes)
    complete_task(old_grant, "confirm_revocation", at: @at + 5.minutes)
    assert_equal "disabled", old_link.reload.status
    verify = replacement.external_access_tasks.find_by!(task_type: "verify_account", status: "pending")
    ExternalAccess::TaskProcessor.call!(task: verify, actor: @admin, action: "complete", external_uid: "2002", at: @at + 6.minutes)

    assert_equal "verified", replacement.reload.status
    assert_equal "revoked", old_grant.reload.status
    new_grant = replacement.external_access_grants.find_by!(status: "grant_due")
    assert_equal old_grant.license, new_grant.license
    assert_equal 1, ExternalAccessGrant.live.where(user: @user, product: @product).count
  end

  test "same numeric identity is recorded as a rename without revoking the active grant" do
    license = create_license(user: @user, starts_on: @at.to_date)
    old_link = submitted_and_verified_link(@user, uid: "3001")
    grant = old_link.external_access_grants.find_by!(license: license)
    complete_task(grant, "send_invite", at: @at)
    complete_task(grant, "confirm_acceptance", at: @at + 1.minute)

    replacement = ExternalAccess::AccountChangeRequest.call!(
      user: @user, current_link: old_link, username: "renamed-account", at: @at + 2.minutes
    )
    task = replacement.external_access_tasks.find_by!(task_type: "process_account_change")
    ExternalAccess::TaskProcessor.call!(
      task: task, actor: @admin, action: "complete", external_uid: "3001", at: @at + 3.minutes
    )

    assert_equal "verified", old_link.reload.status
    assert_equal "renamed-account", old_link.username
    assert_equal "disabled", replacement.reload.status
    assert_equal "active", grant.reload.status
    assert old_link.external_access_events.exists?(action: "link_renamed")
    assert_not grant.external_access_tasks.exists?(task_type: "revoke_access", status: "pending")
  end

  test "failed manual tasks retain limited reasons and can be retried" do
    create_license(user: @user, starts_on: @at.to_date)
    link = submitted_and_verified_link(@user, uid: "4001")
    grant = link.external_access_grants.find_by!(status: "grant_due")
    task = grant.external_access_tasks.find_by!(task_type: "send_invite")

    ExternalAccess::TaskProcessor.call!(
      task: task, actor: @admin, action: "fail", reason_code: "invite_failed",
      retryable: true, internal_note: "manual retry required", at: @at
    )
    assert_equal "failed", task.reload.status
    assert_equal "failed", grant.reload.status
    assert_equal "grant_due", grant.resume_state

    ExternalAccess::TaskProcessor.call!(task: task, actor: @admin, action: "retry", at: @at + 1.minute)
    assert_equal "pending", task.reload.status
    assert_equal "grant_due", grant.reload.status
    assert task.external_access_events.exists?(action: "task_failed", actor: @admin)
    assert task.external_access_events.exists?(action: "task_retried", actor: @admin)
  end

  test "non administrators cannot process tasks and duplicate open tasks remain idempotent" do
    link = ExternalAccess::LinkSubmission.call!(user: @user, username: "secure-user", at: @at)
    task = link.external_access_tasks.find_by!(task_type: "verify_account")

    assert_raises(Pundit::NotAuthorizedError) do
      ExternalAccess::TaskProcessor.call!(task: task, actor: @user, action: "complete", at: @at)
    end
    assert_no_difference "ExternalAccessTask.count" do
      2.times { ExternalAccess::TaskFactory.ensure!(task_type: "verify_account", link: link, due_at: @at) }
    end
  end

  test "disconnect keeps the link until active access revocation is confirmed" do
    license = create_license(user: @user, starts_on: @at.to_date)
    link = submitted_and_verified_link(@user, uid: "5001")
    grant = link.external_access_grants.find_by!(license: license)
    complete_task(grant, "send_invite", at: @at)
    complete_task(grant, "confirm_acceptance", at: @at + 1.minute)

    ExternalAccess::DisconnectRequest.call!(user: @user, link: link, at: @at + 2.minutes)

    assert_equal "change_requested", link.reload.status
    assert_equal "revoke_due", grant.reload.status
    assert grant.external_access_tasks.exists?(task_type: "revoke_access", status: "pending")
    complete_task(grant, "revoke_access", at: @at + 3.minutes)
    complete_task(grant, "confirm_revocation", at: @at + 4.minutes)
    assert_equal "disabled", link.reload.status
  end

  private

  def create_license(user:, starts_on:)
    last_on = starts_on + 1.month - 1.day
    License.create!(
      user: user,
      product: @product,
      source: "paid",
      status: starts_on > @at.to_date ? "scheduled" : "active",
      starts_on: starts_on,
      last_usable_on: last_on,
      access_ends_at: KST.local((last_on + 1.day).year, (last_on + 1.day).month, (last_on + 1.day).day)
    )
  end

  def submitted_and_verified_link(user, uid:)
    link = ExternalAccess::LinkSubmission.call!(user: user, username: "github-#{uid}", at: @at)
    task = link.external_access_tasks.find_by!(task_type: "verify_account")
    ExternalAccess::TaskProcessor.call!(
      task: task, actor: @admin, action: "complete", external_uid: uid, evidence_note: "manual check", at: @at
    )
    link.reload
  end

  def complete_task(grant, task_type, at:)
    task = grant.external_access_tasks.find_by!(task_type: task_type, status: "pending")
    ExternalAccess::TaskProcessor.call!(task: task, actor: @admin, action: "complete", evidence_note: "manual check", at: at)
  end
end
