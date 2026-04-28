class CreateTargets < ActiveRecord::Migration[8.1]
  def change
    create_table :targets do |t|
      t.references :exercise_type, null: false, foreign_key: true
      t.decimal :value, null: false
      t.datetime :applicable_from, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamps
    end
    add_index :targets, [ :exercise_type_id, :applicable_from ]
  end
end
