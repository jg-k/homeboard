class CreateActivityLogComments < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_log_comments do |t|
      t.references :activity_log, null: false, foreign_key: true
      t.text :body, null: false
      t.string :category, null: false

      t.timestamps
    end

    add_index :activity_log_comments, :category
  end
end
