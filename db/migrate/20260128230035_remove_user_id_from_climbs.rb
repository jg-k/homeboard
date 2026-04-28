class RemoveUserIdFromClimbs < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :board_climbs, :users
    remove_index :board_climbs, :user_id
    remove_index :board_climbs, [ :user_id, :climbed_at ]
    remove_column :board_climbs, :user_id, :integer, null: false
  end
end
