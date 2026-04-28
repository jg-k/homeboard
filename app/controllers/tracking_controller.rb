class TrackingController < ApplicationController
  before_action :authenticate_user!

  def index
    @tab = params[:tab].presence || "exercises"
    @exercise_types_by_category = current_user.exercise_types.order(:name).group_by(&:category)
    @categories = @exercise_types_by_category.keys
    @category = params[:category].presence || @categories.first
    @exercise_types = @exercise_types_by_category[@category] || []
    @metrics = current_user.metrics.order(:name)
  end
end
