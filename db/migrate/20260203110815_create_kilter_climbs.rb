class CreateKilterClimbs < ActiveRecord::Migration[8.1]
  def change
    create_table :kilter_climbs do |t|
      t.string :uuid, null: false
      t.string :name
      t.string :setter_username

      t.timestamps
    end
    add_index :kilter_climbs, :uuid, unique: true

    # Track when climbs were last synced (global, not per-user)
    add_column :users, :kilter_climbs_synced_at, :datetime
  end
end
