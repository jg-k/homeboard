class AddUkcFields < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :ukc_user_id, :string
    add_column :users, :ukc_synced_at, :datetime

    add_column :crag_ascents, :ukc_route_id, :string
    add_index :crag_ascents, :ukc_route_id, where: "ukc_route_id IS NOT NULL"
  end
end
