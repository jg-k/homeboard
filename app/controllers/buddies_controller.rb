class BuddiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_followed_user, only: %i[activity day exercise_chart]

  def index
    @followers = current_user.followers
    @following = current_user.following
  end

  def activity
    @activity_data = ActivityCalendar.new(@user).summary_by_date

    @pagy, @activity_logs = pagy(
      @user.activity_logs.includes(loggable: []).chronological,
      limit: 15
    )

    @activity_logs_by_date = @activity_logs.group_by { |log| log.performed_at.to_date }
    assign_loggable_associations(@activity_logs)
  end

  def day
    @date = Date.parse(params[:date])
    @activity_logs = @user.activity_logs
      .where(performed_at: @date.all_day)
      .includes(loggable: [])
      .chronological

    assign_loggable_associations(@activity_logs)
  end

  def exercise_chart
    @exercise_type = @user.exercise_types.find(params[:exercise_type_id])
    @chart_data = @exercise_type.chart_data_with_targets
  end

  def create
    email = params[:email]&.strip&.downcase

    if email.blank?
      redirect_to buddies_path, alert: "Please enter an email address."
      return
    end

    user_to_follow = User.find_by("LOWER(email) = ?", email)

    if user_to_follow.nil?
      redirect_to buddies_path, alert: "No user found with that email."
    elsif user_to_follow == current_user
      redirect_to buddies_path, alert: "You can't follow yourself."
    elsif !user_to_follow.allow_follows
      redirect_to buddies_path, alert: "This user doesn't allow followers."
    elsif current_user.following?(user_to_follow)
      redirect_to buddies_path, alert: "You're already following this user."
    else
      current_user.follow(user_to_follow)
      redirect_to buddies_path, notice: "You are now following #{user_to_follow.email}."
    end
  end

  def destroy
    follow = current_user.active_follows.find_by(followed_id: params[:id])

    if follow
      follow.destroy
      redirect_to buddies_path, notice: "Unfollowed successfully."
    else
      redirect_to buddies_path, alert: "Follow not found."
    end
  end

  private

  def set_followed_user
    @user = current_user.following.find_by(id: params[:id])

    unless @user
      redirect_to buddies_path, alert: "You must be following this user to view their activity."
    end
  end

  def assign_loggable_associations(activity_logs)
    loaded = ActivityLog::Loggables.for(activity_logs)
    @board_climbs_with_associations = loaded[:board_climb]
    @exercises_with_associations = loaded[:exercise]
    @gym_sessions_with_associations = loaded[:gym_session]
    @crag_ascents_with_associations = loaded[:crag_ascent]
    @system_board_climbs_with_associations = loaded[:system_board_climb]
    @hikes_with_associations = loaded[:hike]
  end
end
