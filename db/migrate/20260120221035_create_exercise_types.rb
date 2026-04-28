class CreateExerciseTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :exercise_types do |t|
      t.string :name, null: false
      t.string :unit, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :exercise_types, [ :user_id, :name ], unique: true
  end
end
