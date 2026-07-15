class AddNameToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :name, :string

    User.reset_column_information
    User.update_all(name: "리독스")

    change_column_null :users, :name, false
  end

  def down
    remove_column :users, :name
  end
end
