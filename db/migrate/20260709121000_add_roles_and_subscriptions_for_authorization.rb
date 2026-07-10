class AddRolesAndSubscriptionsForAuthorization < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :integer, null: false, default: 0

    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.boolean :active, null: false, default: false

      t.timestamps
    end
  end
end
