class AddCommerceOperationsAndRefundRequests < ActiveRecord::Migration[8.1]
  def change
    add_reference :orders, :retry_of_order, foreign_key: { to_table: :orders }, index: { unique: true }
    add_column :orders, :abandoned_at, :datetime
    add_column :orders, :last_provider_event_at, :datetime
    add_index :orders, [ :status, :payment_requested_at ]

    add_column :payment_transactions, :provider_status, :string
    add_column :payment_transactions, :provider_observed_at, :datetime

    create_table :refund_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.references :processed_by, foreign_key: { to_table: :users }
      t.string :public_id, null: false
      t.string :status, null: false, default: "requested"
      t.string :reason_code, null: false
      t.text :customer_note
      t.integer :requested_amount, null: false
      t.boolean :full_request, null: false, default: true
      t.text :public_response
      t.text :internal_note
      t.string :provider_refund_status, null: false, default: "not_requested"
      t.boolean :external_refund_confirmed, null: false, default: false
      t.datetime :reviewed_at
      t.datetime :decided_at
      t.datetime :processing_started_at
      t.datetime :external_processed_at
      t.timestamps
    end
    add_index :refund_requests, :public_id, unique: true
    add_index :refund_requests, [ :order_id, :status ]
    add_index :refund_requests, :order_id,
      unique: true,
      where: "status IN ('requested','reviewing','approved','processing')",
      name: "index_refund_requests_on_one_open_per_order"

    create_table :commerce_audit_events do |t|
      t.references :actor, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.string :auditable_type, null: false
      t.integer :auditable_id, null: false
      t.string :from_state
      t.string :to_state
      t.string :reason_code
      t.datetime :occurred_at, null: false
      t.timestamps
    end
    add_index :commerce_audit_events,
      [ :auditable_type, :auditable_id, :occurred_at ],
      name: "index_commerce_audits_on_target_and_time"
    add_index :commerce_audit_events, [ :action, :occurred_at ]
  end
end
