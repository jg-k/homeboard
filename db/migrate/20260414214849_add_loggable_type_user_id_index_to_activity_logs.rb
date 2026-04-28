class AddLoggableTypeUserIdIndexToActivityLogs < ActiveRecord::Migration[8.1]
  def change
    add_index :activity_logs, [ :loggable_type, :user_id ]
  end
end
