class CreateChapterProgresses < ActiveRecord::Migration[8.1]
  def change
    create_table :chapter_progresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :chapter_id, null: false
      t.datetime :completed_at

      t.timestamps
    end

    add_index :chapter_progresses, %i[user_id chapter_id], unique: true
  end
end
