class AddCategoryToExerciseTypes < ActiveRecord::Migration[8.0]
  def change
    add_column :exercise_types, :category, :string, default: "other", null: false
  end
end
