class MakeTargetPolymorphic < ActiveRecord::Migration[8.1]
  def change
    add_column :targets, :targetable_type, :string
    add_column :targets, :targetable_id, :integer

    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE targets
          SET targetable_type = 'ExerciseType',
              targetable_id = exercise_type_id
        SQL
      end
    end

    change_column_null :targets, :targetable_type, false
    change_column_null :targets, :targetable_id, false

    remove_foreign_key :targets, :exercise_types
    remove_index :targets, [ :exercise_type_id, :applicable_from ]
    remove_index :targets, :exercise_type_id
    remove_column :targets, :exercise_type_id, :integer

    add_index :targets, [ :targetable_type, :targetable_id ]
    add_index :targets, [ :targetable_type, :targetable_id, :applicable_from ],
              name: "index_targets_on_targetable_and_applicable_from"
  end
end
