class BackfillActivityLogsForClimbs < ActiveRecord::Migration[8.1]
  def up
    Climb.find_each do |climb|
      ActivityLog.create!(
        user_id: climb.user_id,
        loggable: climb,
        performed_at: climb.climbed_at
      )
    end
  end

  def down
    ActivityLog.where(loggable_type: "Climb").delete_all
  end
end
