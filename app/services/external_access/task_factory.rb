module ExternalAccess
  class TaskFactory
    def self.ensure!(task_type:, link:, grant: nil, license: nil, product: nil, due_at: Time.current, actor: nil)
      dedup_key = [ task_type, link.id, grant&.id, license&.id, product&.id ].join(":")
      existing = ExternalAccessTask.open.find_by(dedup_key: dedup_key)
      return existing if existing

      task = ExternalAccessTask.create!(
        task_type: task_type,
        external_account_link: link,
        external_access_grant: grant,
        license: license || grant&.license,
        product: product || grant&.product,
        due_at: due_at,
        dedup_key: dedup_key
      )
      ExternalAccess::EventRecorder.record!(
        actor: actor,
        action: "task_created",
        subject: task,
        link: link,
        grant: grant,
        task: task,
        from_state: nil,
        to_state: task.status,
        reason_code: task_type,
        at: due_at
      )
      task
    rescue ActiveRecord::RecordNotUnique
      ExternalAccessTask.open.find_by!(dedup_key: dedup_key)
    end
  end
end
