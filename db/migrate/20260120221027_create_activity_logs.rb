class CreateActivityLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :loggable, polymorphic: true, null: false
      t.datetime :performed_at, null: false

      t.timestamps
    end

    add_index :activity_logs, [ :user_id, :performed_at ]
  end
end
