class HikesController < ApplicationController
  before_action :authenticate_user!

  def new
    @hike = Hike.new
  end

  def edit
    @hike = Hike.joins(:activity_log)
                .where(activity_logs: { user_id: current_user.id })
                .find(params[:id])
  end

  def create
    @hike = Hike.new(hike_params)

    if @hike.save
      @hike.create_activity_log!(user: current_user, performed_at: @hike.performed_at || Time.current)
      redirect_to activity_path, notice: "Hike was successfully logged."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @hike = Hike.joins(:activity_log)
                .where(activity_logs: { user_id: current_user.id })
                .find(params[:id])

    if @hike.update(hike_params.except(:performed_at))
      @hike.activity_log.update(performed_at: params[:hike][:performed_at]) if params[:hike][:performed_at].present?
      redirect_to activity_path, notice: "Hike was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    hike = Hike.joins(:activity_log)
               .where(activity_logs: { user_id: current_user.id })
               .find(params[:id])
    hike.destroy
    redirect_to activity_path, notice: "Hike was successfully deleted.", status: :see_other
  end

  private

  def hike_params
    params.require(:hike).permit(:name, :distance_km, :elevation_gain_m, :duration_hours, :notes, :performed_at)
  end
end
