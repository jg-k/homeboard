class CragAscentsController < ApplicationController
  before_action :authenticate_user!

  def destroy
    crag_ascent = CragAscent.joins(:activity_log)
                            .where(activity_logs: { user_id: current_user.id })
                            .find(params[:id])
    crag_ascent.destroy
    redirect_to activity_path, notice: "Outdoor ascent was successfully deleted.", status: :see_other
  end
end
