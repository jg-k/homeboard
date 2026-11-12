class SystemBoardClimbsController < ApplicationController
  before_action :authenticate_user!

  def destroy
    system_board_climb = SystemBoardClimb.joins(:activity_log)
                                         .where(activity_logs: { user_id: current_user.id })
                                         .find(params[:id])
    system_board_climb.destroy
    redirect_to activity_path, notice: "Board climb was successfully deleted.", status: :see_other
  end
end
