class DropRpeFromExercises < ActiveRecord::Migration[8.1]
  def change
    remove_column :exercises, :rpe, :decimal
  end
end
