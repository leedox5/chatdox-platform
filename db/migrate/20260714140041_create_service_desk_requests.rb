class CreateServiceDeskRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :service_desk_requests do |t|
      t.integer :request_number, null: false
      t.date :date, null: false
      t.string :requester, null: false
      t.string :subject, null: false
      t.integer :status, null: false, default: 0
      t.integer :visibility, null: false, default: 0
      t.text :description

      t.timestamps
    end
    add_index :service_desk_requests, :request_number, unique: true
  end
end
