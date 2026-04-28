class BoardseshDataController < ApplicationController
  def destroy
    climb_ids = SystemBoardClimb.joins(:activity_log)
      .where(activity_logs: { user_id: current_user.id })
      .where("system_board_climbs.board LIKE ?", "boardsesh_%")
      .pluck(:id)

    SystemBoardClimb.where(id: climb_ids).destroy_all
    current_user.update!(boardsesh_last_synced_at: nil)

    redirect_to settings_path, notice: "Deleted #{climb_ids.count} Boardsesh climbs."
  end
end
