class AddTossFieldsToSubscriptions < ActiveRecord::Migration[8.1]
  def change
    add_column :subscriptions, :toss_customer_key, :string
    add_column :subscriptions, :toss_billing_key, :string
    add_column :subscriptions, :toss_payment_key, :string
    add_column :subscriptions, :order_id, :string
    add_column :subscriptions, :status, :string, default: "pending"
    add_column :subscriptions, :current_period_start, :datetime
    add_column :subscriptions, :current_period_end, :datetime
    add_column :subscriptions, :cancel_at, :datetime
    add_column :subscriptions, :canceled_at, :datetime

    add_index :subscriptions, :toss_customer_key, unique: true
    add_index :subscriptions, :order_id, unique: true
  end
end
