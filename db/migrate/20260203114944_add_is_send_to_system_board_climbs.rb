class AddIsSendToSystemBoardClimbs < ActiveRecord::Migration[8.1]
  def change
    add_column :system_board_climbs, :is_send, :boolean, default: true, null: false
  end
end
