class AddRepsToExercises < ActiveRecord::Migration[8.1]
  def change
    add_column :exercises, :reps, :integer
  end
end
