class MoveGradingSystemFromProblemsToBoards < ActiveRecord::Migration[8.1]
  def up
    add_reference :boards, :grading_system, foreign_key: true

    # Copy grading_system_id from each board's first problem
    execute <<-SQL
      UPDATE boards
      SET grading_system_id = (
        SELECT p.grading_system_id
        FROM problems p
        JOIN board_layouts bl ON p.board_layout_id = bl.id
        WHERE bl.board_id = boards.id
          AND p.grading_system_id IS NOT NULL
        LIMIT 1
      )
    SQL

    remove_reference :problems, :grading_system, foreign_key: true
  end

  def down
    add_reference :problems, :grading_system, foreign_key: true

    # Copy grading_system_id back from board to its problems
    execute <<-SQL
      UPDATE problems
      SET grading_system_id = (
        SELECT b.grading_system_id
        FROM boards b
        JOIN board_layouts bl ON bl.board_id = b.id
        WHERE bl.id = problems.board_layout_id
      )
    SQL

    remove_reference :boards, :grading_system, foreign_key: true
  end
end
