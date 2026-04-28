class AddAttemptsToBoardClimbs < ActiveRecord::Migration[8.1]
  def change
    add_column :board_climbs, :attempts, :integer, default: 1, null: false
  end
end
