class RemoveUserIdFromGymSessions < ActiveRecord::Migration[8.1]
  def change
    if column_exists?(:gym_sessions, :user_id)
      remove_foreign_key :gym_sessions, :users
      remove_index :gym_sessions, :user_id
      remove_column :gym_sessions, :user_id, :integer, null: false
    end
  end
end
