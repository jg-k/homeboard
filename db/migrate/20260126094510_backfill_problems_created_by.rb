class BackfillProblemsCreatedBy < ActiveRecord::Migration[8.1]
  def up
    execute <<-SQL
      UPDATE problems
      SET created_by_id = (
        SELECT user_boards.user_id
        FROM board_layouts
        JOIN boards ON boards.id = board_layouts.board_id
        JOIN user_boards ON user_boards.board_id = boards.id
        WHERE board_layouts.id = problems.board_layout_id
        LIMIT 1
      )
      WHERE created_by_id IS NULL
    SQL
  end

  def down
    # No rollback needed
  end
end
