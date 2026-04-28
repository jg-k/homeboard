class RenameClimbsToBoardClimbs < ActiveRecord::Migration[8.1]
  def up
    rename_table :climbs, :board_climbs

    # Update polymorphic type references in activity_logs
    execute <<-SQL
      UPDATE activity_logs SET loggable_type = 'BoardClimb' WHERE loggable_type = 'Climb'
    SQL
  end

  def down
    rename_table :board_climbs, :climbs

    execute <<-SQL
      UPDATE activity_logs SET loggable_type = 'Climb' WHERE loggable_type = 'BoardClimb'
    SQL
  end
end
