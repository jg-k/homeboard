class Admin::UsersController < Admin::BaseController
  def index
    @users = User.order(created_at: :desc)
    @user_stats = load_user_stats(@users.pluck(:id))
  end

  def update
    @user = User.find(params[:id])
    new_role = params.dig(:user, :role).to_s

    if User.roles.key?(new_role) && @user.update(role: new_role)
      redirect_to admin_users_path, notice: "User updated."
    else
      redirect_to admin_users_path, alert: "Failed to update user."
    end
  end

  def destroy
    @user = User.find(params[:id])
    if @user == current_user
      redirect_to admin_users_path, alert: "Cannot delete yourself."
    else
      @user.destroy
      redirect_to admin_users_path, notice: "User deleted.", status: :see_other
    end
  end

  private

  def load_user_stats(user_ids)
    boards_count = UserBoard.where(user_id: user_ids).group(:user_id).count
    activity_logs_count = ActivityLog.where(user_id: user_ids).group(:user_id).count
    problems_count = Problem.kept
      .joins(board_layout: { board: :user_boards })
      .where(user_boards: { user_id: user_ids })
      .group("user_boards.user_id")
      .count

    user_ids.index_with do |user_id|
      {
        boards: boards_count[user_id] || 0,
        problems: problems_count[user_id] || 0,
        activity_logs: activity_logs_count[user_id] || 0
      }
    end
  end
end
