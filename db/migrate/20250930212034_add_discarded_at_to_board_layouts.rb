class AddDiscardedAtToBoardLayouts < ActiveRecord::Migration[8.1]
  def change
    add_column :board_layouts, :discarded_at, :datetime
    add_index :board_layouts, :discarded_at
  end
end
