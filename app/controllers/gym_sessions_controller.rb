class GymSessionsController < ApplicationController
  before_action :authenticate_user!

  def new
    @gym_session = GymSession.new(
      number_of_boulders: params[:number_of_boulders],
      number_of_routes: params[:number_of_routes],
      number_of_circuits: params[:number_of_circuits],
      duration_minutes: params[:duration_minutes],
      notes: params[:notes]
    )
  end

  def edit
    @gym_session = GymSession.joins(:activity_log)
                             .where(activity_logs: { user_id: current_user.id })
                             .find(params[:id])
  end

  def create
    @gym_session = GymSession.new(gym_session_params)

    if @gym_session.save
      @gym_session.create_activity_log!(user: current_user, performed_at: @gym_session.performed_at || Time.current)
      redirect_to activity_path, notice: "Gym session was successfully logged."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @gym_session = GymSession.joins(:activity_log)
                             .where(activity_logs: { user_id: current_user.id })
                             .find(params[:id])

    if @gym_session.update(gym_session_params.except(:performed_at))
      @gym_session.activity_log.update(performed_at: params[:gym_session][:performed_at]) if params[:gym_session][:performed_at].present?
      redirect_to activity_path, notice: "Gym session was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    gym_session = GymSession.joins(:activity_log)
                            .where(activity_logs: { user_id: current_user.id })
                            .find(params[:id])
    gym_session.destroy
    redirect_to activity_path, notice: "Gym session was successfully deleted.", status: :see_other
  end

  private

  def gym_session_params
    params.require(:gym_session).permit(:number_of_boulders, :number_of_routes, :number_of_circuits, :duration_minutes, :notes, :performed_at)
  end
end
