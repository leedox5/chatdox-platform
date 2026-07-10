class AddProviderFieldsToSubscriptions < ActiveRecord::Migration[8.1]
  class SubscriptionRecord < ActiveRecord::Base
    self.table_name = "subscriptions"
  end

  def change
    add_column :subscriptions, :provider, :string
    add_column :subscriptions, :provider_customer_id, :string
    add_column :subscriptions, :billing_key, :string

    reversible do |dir|
      dir.up do
        SubscriptionRecord.reset_column_information
        SubscriptionRecord.find_each do |subscription|
          subscription.update_columns(
            provider: "toss",
            provider_customer_id: subscription.toss_customer_key.presence || "user-#{subscription.user_id}",
            billing_key: subscription.toss_billing_key
          )
        end
      end
    end

    add_index :subscriptions, %i[provider provider_customer_id], unique: true
    change_column_null :subscriptions, :provider, false
    change_column_null :subscriptions, :provider_customer_id, false
  end
end
