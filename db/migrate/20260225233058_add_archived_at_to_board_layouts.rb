class AddArchivedAtToBoardLayouts < ActiveRecord::Migration[8.1]
  def change
    add_column :board_layouts, :archived_at, :datetime
  end
end
