class CreateExternalAccessOperations < ActiveRecord::Migration[8.1]
  def change
    create_table :external_account_links do |t|
      t.references :user, null: false, foreign_key: true
      t.references :replaces_link, foreign_key: { to_table: :external_account_links }, index: { unique: true }
      t.string :public_id, null: false
      t.string :provider, null: false, default: "github"
      t.string :username, null: false
      t.string :normalized_username, null: false
      t.string :external_uid
      t.string :status, null: false, default: "pending_verification"
      t.datetime :verified_at
      t.datetime :change_requested_at
      t.datetime :disabled_at
      t.timestamps
    end
    add_index :external_account_links, :public_id, unique: true
    add_index :external_account_links, [ :provider, :normalized_username ],
      unique: true,
      where: "status != 'disabled'",
      name: "idx_external_links_on_active_provider_username"
    add_index :external_account_links, [ :provider, :external_uid ],
      unique: true,
      where: "external_uid IS NOT NULL AND status != 'disabled'",
      name: "idx_external_links_on_active_provider_uid"

    create_table :external_access_grants do |t|
      t.references :user, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :license, null: false, foreign_key: true
      t.references :external_account_link, null: false, foreign_key: true
      t.string :public_id, null: false
      t.string :repository_key, null: false, default: "chatdox_lab"
      t.string :status, null: false, default: "pending"
      t.string :resume_state
      t.string :failure_reason_code
      t.boolean :retryable, null: false, default: true
      t.text :public_message
      t.text :internal_note
      t.datetime :invited_at
      t.datetime :accepted_at
      t.datetime :revoke_due_at
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :external_access_grants, :public_id, unique: true
    add_index :external_access_grants,
      [ :license_id, :external_account_link_id, :repository_key ],
      unique: true,
      name: "idx_external_grants_on_license_link_repository"
    add_index :external_access_grants, [ :user_id, :product_id ],
      unique: true,
      where: "status IN ('grant_due','invited','active','revoke_due')",
      name: "idx_external_grants_on_one_live_user_product"

    create_table :external_access_tasks do |t|
      t.references :external_account_link, null: false, foreign_key: true
      t.references :external_access_grant, foreign_key: true
      t.references :license, foreign_key: true
      t.references :product, foreign_key: true
      t.references :processed_by, foreign_key: { to_table: :users }
      t.string :public_id, null: false
      t.string :dedup_key, null: false
      t.string :task_type, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :due_at, null: false
      t.datetime :completed_at
      t.string :reason_code
      t.boolean :retryable, null: false, default: true
      t.text :evidence_note
      t.text :public_message
      t.text :internal_note
      t.timestamps
    end
    add_index :external_access_tasks, :public_id, unique: true
    add_index :external_access_tasks, [ :status, :due_at ]
    add_index :external_access_tasks, :dedup_key,
      unique: true,
      where: "status IN ('pending','failed')",
      name: "idx_external_access_tasks_on_one_open_dedup_key"

    create_table :external_access_events do |t|
      t.references :actor, foreign_key: { to_table: :users }
      t.references :external_account_link, foreign_key: true
      t.references :external_access_grant, foreign_key: true
      t.references :external_access_task, foreign_key: true
      t.string :action, null: false
      t.string :subject_type, null: false
      t.integer :subject_id, null: false
      t.string :from_state
      t.string :to_state
      t.string :reason_code
      t.text :evidence_note
      t.datetime :occurred_at, null: false
      t.timestamps
    end
    add_index :external_access_events,
      [ :subject_type, :subject_id, :occurred_at ],
      name: "idx_external_access_events_on_subject_and_time"
    add_index :external_access_events, [ :action, :occurred_at ]
  end
end
