class FixBoardLayoutsActiveUniqueIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :board_layouts, name: "index_board_layouts_on_board_id_and_active_unique"
    add_index :board_layouts, [ :board_id, :active ],
      unique: true,
      where: "active = true AND discarded_at IS NULL",
      name: "index_board_layouts_on_board_id_and_active_unique"
  end
end
