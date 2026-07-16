class SimplifyGithubAccessMvp < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :external_access_events, :external_access_grants
    remove_foreign_key :external_access_events, :external_access_tasks
    remove_foreign_key :external_access_events, :external_account_links
    remove_foreign_key :external_access_events, :users, column: :actor_id
    drop_table :external_access_events do |t|
      t.string "action", null: false
      t.integer "actor_id"
      t.datetime "created_at", null: false
      t.text "evidence_note"
      t.integer "external_access_grant_id"
      t.integer "external_access_task_id"
      t.integer "external_account_link_id"
      t.string "from_state"
      t.datetime "occurred_at", null: false
      t.string "reason_code"
      t.integer "subject_id", null: false
      t.string "subject_type", null: false
      t.string "to_state"
      t.datetime "updated_at", null: false
      t.index [ "action", "occurred_at" ], name: "index_external_access_events_on_action_and_occurred_at"
      t.index [ "actor_id" ], name: "index_external_access_events_on_actor_id"
      t.index [ "external_access_grant_id" ], name: "index_external_access_events_on_external_access_grant_id"
      t.index [ "external_access_task_id" ], name: "index_external_access_events_on_external_access_task_id"
      t.index [ "external_account_link_id" ], name: "index_external_access_events_on_external_account_link_id"
      t.index [ "subject_type", "subject_id", "occurred_at" ], name: "idx_external_access_events_on_subject_and_time"
    end

    remove_foreign_key :external_access_tasks, :external_access_grants
    remove_foreign_key :external_access_tasks, :external_account_links
    remove_foreign_key :external_access_tasks, :licenses
    remove_foreign_key :external_access_tasks, :products
    remove_foreign_key :external_access_tasks, :users, column: :processed_by_id
    drop_table :external_access_tasks do |t|
      t.datetime "completed_at"
      t.datetime "created_at", null: false
      t.string "dedup_key", null: false
      t.datetime "due_at", null: false
      t.text "evidence_note"
      t.integer "external_access_grant_id"
      t.integer "external_account_link_id", null: false
      t.text "internal_note"
      t.integer "license_id"
      t.integer "processed_by_id"
      t.integer "product_id"
      t.string "public_id", null: false
      t.text "public_message"
      t.string "reason_code"
      t.boolean "retryable", default: true, null: false
      t.string "status", default: "pending", null: false
      t.string "task_type", null: false
      t.datetime "updated_at", null: false
      t.index [ "dedup_key" ], name: "idx_external_access_tasks_on_one_open_dedup_key", unique: true, where: "status IN ('pending','failed')"
      t.index [ "external_access_grant_id" ], name: "index_external_access_tasks_on_external_access_grant_id"
      t.index [ "external_account_link_id" ], name: "index_external_access_tasks_on_external_account_link_id"
      t.index [ "license_id" ], name: "index_external_access_tasks_on_license_id"
      t.index [ "processed_by_id" ], name: "index_external_access_tasks_on_processed_by_id"
      t.index [ "product_id" ], name: "index_external_access_tasks_on_product_id"
      t.index [ "public_id" ], name: "index_external_access_tasks_on_public_id", unique: true
      t.index [ "status", "due_at" ], name: "index_external_access_tasks_on_status_and_due_at"
    end

    remove_foreign_key :external_access_grants, :external_account_links
    remove_foreign_key :external_access_grants, :licenses
    remove_foreign_key :external_access_grants, :products
    remove_foreign_key :external_access_grants, :users
    drop_table :external_access_grants do |t|
      t.datetime "accepted_at"
      t.datetime "created_at", null: false
      t.integer "external_account_link_id", null: false
      t.string "failure_reason_code"
      t.text "internal_note"
      t.datetime "invited_at"
      t.integer "license_id", null: false
      t.integer "product_id", null: false
      t.string "public_id", null: false
      t.text "public_message"
      t.string "repository_key", default: "chatdox_lab", null: false
      t.string "resume_state"
      t.boolean "retryable", default: true, null: false
      t.datetime "revoke_due_at"
      t.datetime "revoked_at"
      t.string "status", default: "pending", null: false
      t.datetime "updated_at", null: false
      t.integer "user_id", null: false
      t.index [ "external_account_link_id" ], name: "index_external_access_grants_on_external_account_link_id"
      t.index [ "license_id", "external_account_link_id", "repository_key" ], name: "idx_external_grants_on_license_link_repository", unique: true
      t.index [ "license_id" ], name: "index_external_access_grants_on_license_id"
      t.index [ "product_id" ], name: "index_external_access_grants_on_product_id"
      t.index [ "public_id" ], name: "index_external_access_grants_on_public_id", unique: true
      t.index [ "user_id", "product_id" ], name: "idx_external_grants_on_one_live_user_product", unique: true, where: "status IN ('grant_due','invited','active','revoke_due')"
      t.index [ "user_id" ], name: "index_external_access_grants_on_user_id"
    end

    remove_foreign_key :external_account_links, column: :replaces_link_id
    remove_index :external_account_links, name: "idx_external_links_on_active_provider_uid"
    remove_index :external_account_links, name: "idx_external_links_on_active_provider_username"
    remove_index :external_account_links, :replaces_link_id
    remove_index :external_account_links, :user_id

    remove_column :external_account_links, :status, :string, default: "pending_verification", null: false
    remove_column :external_account_links, :verified_at, :datetime
    remove_column :external_account_links, :disabled_at, :datetime
    remove_column :external_account_links, :change_requested_at, :datetime
    remove_column :external_account_links, :replaces_link_id, :integer
    remove_column :external_account_links, :external_uid, :string

    add_column :external_account_links, :invited_at, :datetime
    add_column :external_account_links, :revoked_at, :datetime

    add_index :external_account_links, :user_id, unique: true
  end
end
