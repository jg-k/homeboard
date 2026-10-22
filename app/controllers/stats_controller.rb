class StatsController < ApplicationController
  before_action :authenticate_user!

  def index
    @tab = params[:tab] || "overview"
    @period = Charts::Period.find(params[:period])
    @climbing_chart_data = Charts::Climbing.new(current_user, period: @period).series
    @exercise_chart_data = Charts::Exercise.new(current_user, period: @period).series
    @grade_pyramids = Charts::Grades.new(current_user, period: @period).pyramids if @tab == "overview"

    if @tab == "fitness"
      @exercise_types_by_category = current_user.exercise_types.includes(:exercises).order(:name).group_by(&:category)
      @categories = @exercise_types_by_category.keys
      @category = params[:category].presence || @categories.first
      @exercise_types = @exercise_types_by_category[@category] || []
      @progress_choice = Charts::Progress::Choice.from(params)
      @progress_by_type = @exercise_types.index_with { Charts::Progress.new(_1, choice: @progress_choice) }
    end
  end
end
