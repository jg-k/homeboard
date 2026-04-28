class AddRestSecondsToExercises < ActiveRecord::Migration[8.1]
  def change
    add_column :exercises, :rest_seconds, :integer
  end
end
