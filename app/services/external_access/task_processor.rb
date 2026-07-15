module ExternalAccess
  class TaskProcessor
    class InvalidAction < StandardError; end

    def self.call!(task:, actor:, action:, external_uid: nil, evidence_note: nil,
      public_message: nil, internal_note: nil, reason_code: nil, retryable: true, at: Time.current)
      new(
        task: task, actor: actor, action: action, external_uid: external_uid,
        evidence_note: evidence_note, public_message: public_message,
        internal_note: internal_note, reason_code: reason_code,
        retryable: retryable, at: at
      ).call!
    end

    def initialize(task:, actor:, action:, external_uid:, evidence_note:, public_message:,
      internal_note:, reason_code:, retryable:, at:)
      @task = task
      @actor = actor
      @action = action.to_s
      @external_uid = external_uid.to_s.strip.presence
      @evidence_note = evidence_note
      @public_message = public_message
      @internal_note = internal_note
      @reason_code = reason_code
      @retryable = ActiveModel::Type::Boolean.new.cast(retryable)
      @at = at
    end

    def call!
      raise Pundit::NotAuthorizedError unless @actor&.admin?

      result = ApplicationRecord.transaction do
        @task.lock!
        case @action
        when "complete" then complete!
        when "fail" then fail!
        when "retry" then retry!
        else raise InvalidAction, "unsupported task action"
        end
        @task
      end
      ExternalAccess::DueProcessor.call!(at: @at) if @action == "complete"
      result.reload
    end

    private

    def complete!
      raise InvalidAction, "task is not pending" unless @task.status == "pending"

      case @task.task_type
      when "verify_account" then verify_account!
      when "send_invite" then send_invite!
      when "confirm_acceptance" then confirm_acceptance!
      when "revoke_access" then record_revoke!
      when "confirm_revocation" then confirm_revocation!
      when "process_account_change" then process_account_change!
      else raise InvalidAction, "unknown task type"
      end
      finish_task!("completed", "task_completed")
    end

    def verify_account!
      link = @task.external_account_link
      link.lock!
      raise InvalidAction, "link is not pending" unless link.status == "pending_verification"
      if link.replaces_link && link.replaces_link.status != "disabled"
        raise InvalidAction, "previous access must be revoked first"
      end

      previous = link.status
      link.update!(status: "verified", external_uid: @external_uid, verified_at: @at)
      record_subject!("link_verified", link, previous, link.status, "manual_identity_check")
    end

    def send_invite!
      grant = locked_grant!("grant_due")
      previous = grant.status
      grant.transition_to!("invited", { invited_at: @at, public_message: @public_message, internal_note: @internal_note }, at: @at)
      record_subject!("grant_invited", grant, previous, grant.status, "manual_invite_recorded")
      TaskFactory.ensure!(task_type: "confirm_acceptance", link: grant.external_account_link, grant: grant, due_at: @at, actor: @actor)
    end

    def confirm_acceptance!
      grant = locked_grant!("invited")
      previous = grant.status
      grant.transition_to!("active", { accepted_at: @at, public_message: @public_message, internal_note: @internal_note }, at: @at)
      record_subject!("grant_activated", grant, previous, grant.status, "manual_acceptance_confirmed")
    end

    def record_revoke!
      grant = locked_grant!("revoke_due")
      TaskFactory.ensure!(task_type: "confirm_revocation", link: grant.external_account_link, grant: grant, due_at: @at, actor: @actor)
    end

    def confirm_revocation!
      grant = locked_grant!("revoke_due")
      previous = grant.status
      grant.transition_to!("revoked", { revoked_at: @at, public_message: @public_message, internal_note: @internal_note })
      record_subject!("grant_revoked", grant, previous, grant.status, "manual_revocation_confirmed")
      finalize_link_after_revocation!(grant.external_account_link)
    end

    def process_account_change!
      replacement = @task.external_account_link
      replacement.lock!
      previous_link = replacement.replaces_link
      raise InvalidAction, "replacement link is invalid" unless previous_link&.status == "change_requested"

      previous_link.lock!
      if @external_uid.present? && previous_link.external_uid == @external_uid
        apply_rename!(previous_link, replacement)
      else
        replacement.update!(external_uid: @external_uid)
        live_grants = previous_link.external_access_grants.live.lock.to_a
        if live_grants.empty?
          disable_link!(previous_link, "replacement_without_live_grant")
          TaskFactory.ensure!(task_type: "verify_account", link: replacement, due_at: @at, actor: @actor)
        else
          live_grants.each { |grant| DueProcessor.mark_revoke_due!(grant: grant, at: @at, actor: @actor) }
        end
      end
    end

    def apply_rename!(previous_link, replacement)
      old_username = previous_link.normalized_username
      replacement.update!(status: "disabled", disabled_at: @at)
      previous_link.update!(
        username: replacement.username,
        normalized_username: replacement.normalized_username,
        status: "verified",
        change_requested_at: nil
      )
      record_subject!(
        "link_renamed", previous_link, "change_requested", previous_link.status,
        "same_external_uid", "#{old_username} -> #{previous_link.normalized_username}"
      )
      record_subject!("link_disabled", replacement, "pending_verification", replacement.status, "rename_candidate_closed")
    end

    def fail!
      raise InvalidAction, "task is not pending" unless @task.status == "pending"
      raise InvalidAction, "failure reason is required" unless ExternalAccessTask::REASON_CODES.include?(@reason_code)

      if (grant = @task.external_access_grant)
        grant.lock!
        unless %w[revoked failed].include?(grant.status)
          previous = grant.status
          grant.transition_to!("failed", {
            resume_state: previous,
            failure_reason_code: @reason_code,
            retryable: @retryable,
            internal_note: @internal_note
          })
          record_subject!("grant_failed", grant, previous, grant.status, @reason_code)
        end
      end
      finish_task!("failed", "task_failed")
    end

    def retry!
      raise InvalidAction, "task is not retryable" unless @task.status == "failed" && @task.retryable?

      if (grant = @task.external_access_grant)
        grant.lock!
        if grant.status == "failed"
          previous = grant.status
          resume_state = grant.resume_state || raise(InvalidAction, "grant resume state is missing")
          grant.transition_to!(resume_state, {
            resume_state: nil,
            failure_reason_code: nil,
            retryable: true
          }, at: @at)
          record_subject!("grant_retried", grant, previous, grant.status, "manual_retry")
        end
      end
      previous = @task.status
      @task.update!(status: "pending", reason_code: nil, completed_at: nil, processed_by: @actor)
      EventRecorder.record!(
        actor: @actor,
        action: "task_retried",
        subject: @task,
        task: @task,
        from_state: previous,
        to_state: @task.status,
        reason_code: "manual_retry",
        at: @at
      )
    end

    def locked_grant!(expected_status)
      grant = @task.external_access_grant || raise(InvalidAction, "grant is missing")
      grant.lock!
      raise InvalidAction, "grant state does not match the task" unless grant.status == expected_status

      grant
    end

    def finish_task!(status, action)
      previous = @task.status
      @task.update!(
        status: status,
        processed_by: @actor,
        completed_at: status == "completed" ? @at : nil,
        reason_code: status == "failed" ? @reason_code : nil,
        retryable: @retryable,
        evidence_note: @evidence_note,
        public_message: @public_message,
        internal_note: @internal_note
      )
      EventRecorder.record!(
        actor: @actor,
        action: action,
        subject: @task,
        task: @task,
        from_state: previous,
        to_state: @task.status,
        reason_code: @task.reason_code || @task.task_type,
        evidence_note: @evidence_note,
        at: @at
      )
    end

    def finalize_link_after_revocation!(link)
      return unless link.status == "change_requested"
      return if link.external_access_grants.live.where.not(status: "revoked").exists?

      disable_link!(link, link.replacement_link ? "replacement_revoke_complete" : "disconnect_revoke_complete")
      if (replacement = link.replacement_link)
        TaskFactory.ensure!(task_type: "verify_account", link: replacement, due_at: @at, actor: @actor)
      end
    end

    def disable_link!(link, reason)
      previous = link.status
      link.update!(status: "disabled", disabled_at: @at)
      record_subject!("link_disabled", link, previous, link.status, reason)
    end

    def record_subject!(action, subject, from_state, to_state, reason_code, evidence = @evidence_note)
      EventRecorder.record!(
        actor: @actor,
        action: action,
        subject: subject,
        task: @task,
        from_state: from_state,
        to_state: to_state,
        reason_code: reason_code,
        evidence_note: evidence,
        at: @at
      )
    end
  end
end
