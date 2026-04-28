class AddActiveToBoardLayouts < ActiveRecord::Migration[8.1]
  def change
    add_column :board_layouts, :active, :boolean, default: false, null: false
    add_index :board_layouts, [ :board_id, :active ], unique: true, where: "active = true", name: "index_board_layouts_on_board_id_and_active_unique"
  end
end
