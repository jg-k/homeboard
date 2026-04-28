class AddRepsAndRpeToExercises < ActiveRecord::Migration[8.1]
  def change
    add_column :exercises, :reps, :integer
    add_column :exercises, :rpe, :decimal
  end
end
