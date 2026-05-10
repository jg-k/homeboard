class ActivityLogCommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_activity_log, only: %i[new create edit update destroy]
  before_action :set_comment, only: %i[edit update destroy]

  def index
    @category = params[:category].presence_in(ActivityLogComment::CATEGORIES)
    scope = ActivityLogComment
      .joins(:activity_log)
      .where(activity_logs: { user_id: current_user.id })
      .includes(activity_log: :loggable)
      .order(created_at: :desc)
    scope = scope.where(category: @category) if @category
    @comments = scope
    @counts = ActivityLogComment
      .joins(:activity_log)
      .where(activity_logs: { user_id: current_user.id })
      .group(:category).count
  end

  def new
    @comment = @activity_log.comments.build
  end

  def create
    @comment = @activity_log.comments.build(comment_params)
    if @comment.save
      redirect_to activity_path, notice: "Comment added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @comment.update(comment_params)
      redirect_to activity_path, notice: "Comment updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @comment.destroy
    redirect_to activity_path, notice: "Comment deleted.", status: :see_other
  end

  private

  def set_activity_log
    @activity_log = current_user.activity_logs.find(params[:activity_log_id])
  end

  def set_comment
    @comment = @activity_log.comments.find(params[:id])
  end

  def comment_params
    params.require(:activity_log_comment).permit(:body, :category)
  end
end
