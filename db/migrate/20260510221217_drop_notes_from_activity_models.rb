class DropNotesFromActivityModels < ActiveRecord::Migration[8.1]
  def change
    remove_column :exercises, :notes, :text
    remove_column :gym_sessions, :notes, :text
    remove_column :hikes, :notes, :text
    remove_column :board_climbs, :notes, :text
  end
end
