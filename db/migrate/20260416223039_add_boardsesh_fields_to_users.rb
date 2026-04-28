class AddBoardseshFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :boardsesh_session_token, :string
    add_column :users, :boardsesh_user_id, :string
    add_column :users, :boardsesh_email, :string
    add_column :users, :boardsesh_last_synced_at, :datetime
  end
end
