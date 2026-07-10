class EnforceSubscriptionProviderFields < ActiveRecord::Migration[8.1]
  class SubscriptionRecord < ActiveRecord::Base
    self.table_name = "subscriptions"
  end

  def up
    SubscriptionRecord.reset_column_information
    SubscriptionRecord.find_each do |subscription|
      updates = {}
      updates[:provider] = "toss" if subscription.provider.blank?
      if subscription.provider_customer_id.blank?
        updates[:provider_customer_id] = subscription.toss_customer_key.presence || "user-#{subscription.user_id}"
      end
      updates[:status] = "pending" if subscription.status.blank?
      subscription.update_columns(updates) if updates.any?
    end

    change_column_null :subscriptions, :provider, false
    change_column_null :subscriptions, :provider_customer_id, false
    change_column_null :subscriptions, :status, false
  end

  def down
    change_column_null :subscriptions, :status, true
    change_column_null :subscriptions, :provider_customer_id, true
    change_column_null :subscriptions, :provider, true
  end
end
