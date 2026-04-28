class MoveRepsAndRestSecondsToExerciseTypes < ActiveRecord::Migration[8.1]
  def up
    add_column :exercise_types, :reps, :integer
    add_column :exercise_types, :rest_seconds, :integer

    # Copy the most common reps/rest_seconds per exercise_type
    execute <<~SQL
      UPDATE exercise_types
      SET reps = (
        SELECT exercises.reps
        FROM exercises
        WHERE exercises.exercise_type_id = exercise_types.id
          AND exercises.reps IS NOT NULL
        GROUP BY exercises.reps
        ORDER BY COUNT(*) DESC
        LIMIT 1
      ),
      rest_seconds = (
        SELECT exercises.rest_seconds
        FROM exercises
        WHERE exercises.exercise_type_id = exercise_types.id
          AND exercises.rest_seconds IS NOT NULL
        GROUP BY exercises.rest_seconds
        ORDER BY COUNT(*) DESC
        LIMIT 1
      )
    SQL

    remove_column :exercises, :reps
    remove_column :exercises, :rest_seconds
  end

  def down
    add_column :exercises, :reps, :integer
    add_column :exercises, :rest_seconds, :integer

    execute <<~SQL
      UPDATE exercises
      SET reps = (SELECT exercise_types.reps FROM exercise_types WHERE exercise_types.id = exercises.exercise_type_id),
          rest_seconds = (SELECT exercise_types.rest_seconds FROM exercise_types WHERE exercise_types.id = exercises.exercise_type_id)
    SQL

    remove_column :exercise_types, :reps
    remove_column :exercise_types, :rest_seconds
  end
end
