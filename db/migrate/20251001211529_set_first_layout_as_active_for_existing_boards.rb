class SetFirstLayoutAsActiveForExistingBoards < ActiveRecord::Migration[8.1]
  def up
    # For each board, set the first (oldest) layout as active
    Board.includes(:board_layouts).each do |board|
      first_layout = board.board_layouts.where(discarded_at: nil).order(:created_at).first
      if first_layout
        first_layout.update_column(:active, true)
      end
    end
  end

  def down
    # Reset all layouts to inactive
    BoardLayout.update_all(active: false)
  end
end
