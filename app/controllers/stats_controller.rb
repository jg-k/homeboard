class StatsController < ApplicationController
  before_action :authenticate_user!

  def index
    @tab = params[:tab] || "overview"
    @period = Charts::Period.find(params[:period])
    @climbing_chart_data = Charts::Climbing.new(current_user, period: @period).series
    @exercise_chart_data = Charts::Exercise.new(current_user, period: @period).series

    if @tab == "fitness"
      @exercise_types_by_category = current_user.exercise_types.includes(:exercises).order(:name).group_by(&:category)
      @categories = @exercise_types_by_category.keys
      @category = params[:category].presence || @categories.first
      @exercise_types = @exercise_types_by_category[@category] || []
    end
  end
end
