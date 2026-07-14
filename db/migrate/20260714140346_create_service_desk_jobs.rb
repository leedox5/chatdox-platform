class CreateServiceDeskJobs < ActiveRecord::Migration[8.1]
  def change
    create_table :service_desk_jobs do |t|
      t.references :service_desk_request, null: false, foreign_key: true
      t.integer :job_number, null: false
      t.string :author, null: false
      t.datetime :performed_at, null: false
      t.text :content

      t.timestamps
    end

    add_index :service_desk_jobs, %i[service_desk_request_id job_number], unique: true
  end
end
