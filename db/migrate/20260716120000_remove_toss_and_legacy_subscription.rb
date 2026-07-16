class RemoveTossAndLegacySubscription < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :payment_transactions, :subscriptions
    remove_index :payment_transactions, :subscription_id
    remove_column :payment_transactions, :subscription_id, :integer

    drop_table :subscriptions do |t|
      t.boolean "active", default: false, null: false
      t.string "billing_key"
      t.datetime "cancel_at"
      t.datetime "canceled_at"
      t.datetime "created_at", null: false
      t.datetime "current_period_end"
      t.datetime "current_period_start"
      t.string "order_id"
      t.string "provider", null: false
      t.string "provider_customer_id", null: false
      t.string "status", default: "pending", null: false
      t.string "toss_billing_key"
      t.string "toss_customer_key"
      t.string "toss_payment_key"
      t.datetime "updated_at", null: false
      t.integer "user_id", null: false
      t.index [ "order_id" ], unique: true
      t.index [ "provider", "provider_customer_id" ], unique: true
      t.index [ "toss_customer_key" ], unique: true
      t.index [ "user_id" ], unique: true
    end
  end
end
