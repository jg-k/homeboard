class ExerciseTypesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_exercise_type, only: %i[show edit update destroy]

  def index
    redirect_to tracking_path(tab: "exercises")
  end

  def new
    @exercise_type = current_user.exercise_types.build
  end

  def show
    @chart_data = @exercise_type.chart_data_with_targets
    @exercises = @exercise_type.exercises
                               .joins(:activity_log)
                               .includes(:activity_log)
                               .order("activity_logs.performed_at DESC")
  end

  def edit
    @return_to = safe_return_to
  end

  def create
    @exercise_type = current_user.exercise_types.build(exercise_type_params)

    if @exercise_type.save
      create_initial_target if params[:exercise_type][:initial_target].present?
      redirect_to exercise_types_path, notice: "Exercise type was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @exercise_type.update(exercise_type_params)
      redirect_to safe_return_to.presence || exercise_types_path, notice: "Exercise type was successfully updated."
    else
      @return_to = safe_return_to
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @exercise_type.destroy
    redirect_to exercise_types_path, notice: "Exercise type was successfully deleted.", status: :see_other
  end

  private

  def set_exercise_type
    @exercise_type = current_user.exercise_types.find(params[:id])
  end

  def exercise_type_params
    params.require(:exercise_type).permit(:name, :unit, :category, :initial_target, :added_weight_possible, :reps, :rest_seconds)
  end

  def create_initial_target
    @exercise_type.targets.create(
      value: params[:exercise_type][:initial_target],
      applicable_from: Time.current
    )
  end
end
