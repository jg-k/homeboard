class TargetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_exercise_type

  def create
    @target = @exercise_type.targets.build(target_params)

    if @target.save
      redirect_back fallback_location: exercise_types_path, notice: "Target set"
    else
      redirect_back fallback_location: exercise_types_path, alert: "Failed to set target"
    end
  end

  def destroy
    @target = @exercise_type.targets.find(params[:id])
    @target.destroy
    redirect_back fallback_location: exercise_types_path, notice: "Target deleted"
  end

  private

  def set_exercise_type
    @exercise_type = current_user.exercise_types.find(params[:exercise_type_id])
  end

  def target_params
    params.require(:target).permit(:value, :applicable_from)
  end
end
