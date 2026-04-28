class DropKilterTablesAndColumns < ActiveRecord::Migration[8.1]
  def change
    drop_table :kilter_climbs do |t|
      t.datetime :created_at, null: false
      t.string :name
      t.string :setter_username
      t.datetime :updated_at, null: false
      t.string :uuid, null: false
      t.index [ :uuid ], unique: true
    end

    remove_column :users, :kilter_token, :string
    remove_column :users, :kilter_username, :string
    remove_column :users, :kilter_user_id, :integer
    remove_column :users, :kilter_climbs_synced_at, :datetime
    remove_column :users, :kilter_last_synced_at, :datetime
  end
end
