class AddProductCodeToChapterProgresses < ActiveRecord::Migration[8.1]
  def up
    add_column :chapter_progresses, :product_code, :string

    ChapterProgress.reset_column_information
    ChapterProgress.update_all(product_code: "chatdox")

    change_column_null :chapter_progresses, :product_code, false

    remove_index :chapter_progresses, [ :user_id, :chapter_id ]
    add_index :chapter_progresses, [ :user_id, :chapter_id, :product_code ], unique: true
  end

  def down
    remove_index :chapter_progresses, [ :user_id, :chapter_id, :product_code ]
    add_index :chapter_progresses, [ :user_id, :chapter_id ], unique: true

    remove_column :chapter_progresses, :product_code
  end
end
