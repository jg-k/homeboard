class CreateExercises < ActiveRecord::Migration[8.1]
  def change
    create_table :exercises do |t|
      t.references :exercise_type, null: false, foreign_key: true
      t.decimal :value
      t.text :notes

      t.timestamps
    end
  end
end
