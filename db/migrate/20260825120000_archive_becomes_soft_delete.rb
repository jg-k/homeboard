# Archiving a layout used to be its own state, separate from deleting it, and
# the two overlapped confusingly. Archive now means soft delete, so fold the
# archived rows into discarded ones -- taking their problems along, which is
# what archiving should have done all along -- and drop the column.
class ArchiveBecomesSoftDelete < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE problems
      SET discarded_at = (
        SELECT board_layouts.archived_at FROM board_layouts
        WHERE board_layouts.id = problems.board_layout_id
      )
      WHERE discarded_at IS NULL
        AND board_layout_id IN (SELECT id FROM board_layouts WHERE archived_at IS NOT NULL)
    SQL

    execute <<~SQL
      UPDATE board_layouts
      SET discarded_at = archived_at
      WHERE discarded_at IS NULL AND archived_at IS NOT NULL
    SQL

    remove_column :board_layouts, :archived_at
  end

  def down
    add_column :board_layouts, :archived_at, :datetime
  end
end
