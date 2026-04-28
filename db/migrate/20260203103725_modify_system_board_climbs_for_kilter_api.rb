class ModifySystemBoardClimbsForKilterApi < ActiveRecord::Migration[8.1]
  def change
    # Create system_board_climbs table (fresh, not modifying)
    create_table :system_board_climbs do |t|
      t.string :uuid, null: false, index: { unique: true }
      t.string :climb_uuid
      t.string :board, null: false
      t.string :climb_name, null: false
      t.string :setter_username
      t.datetime :climbed_at, null: false
      t.integer :angle
      t.integer :attempts
      t.integer :quality
      t.string :displayed_grade
      t.boolean :is_benchmark, default: false
      t.boolean :is_mirror, default: false
      t.text :comment

      t.timestamps
    end

    # Add Kilter credentials to users
    change_table :users do |t|
      t.string :kilter_username
      t.string :kilter_token
      t.integer :kilter_user_id
      t.datetime :kilter_last_synced_at
    end
  end
end
