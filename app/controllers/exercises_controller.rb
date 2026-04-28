class ExercisesController < ApplicationController
  before_action :authenticate_user!

  def new
    @exercise = Exercise.new(exercise_type_id: params[:exercise_type_id], value: params[:value], added_weight: params[:added_weight], reps: params[:reps])
    @category = params[:category]
    @exercise_types = if @category.present?
      current_user.exercise_types.where(category: @category).order(:name)
    else
      current_user.exercise_types.order(:name)
    end
  end

  def edit
    @exercise = Exercise.joins(:exercise_type).where(exercise_types: { user_id: current_user.id }).find(params[:id])
    @exercise_types = current_user.exercise_types.order(:name)
    @return_to = safe_return_to
  end

  def create
    @exercise_types = current_user.exercise_types.order(:name)
    exercise_type = current_user.exercise_types.find_by(id: params[:exercise][:exercise_type_id])

    if exercise_type.nil?
      @exercise = Exercise.new(exercise_params)
      @exercise.errors.add(:exercise_type_id, "must be selected")
      render :new, status: :unprocessable_entity
      return
    end

    @exercise = exercise_type.exercises.build(exercise_params)

    if @exercise.save
      redirect_to activity_path, notice: "Activity was successfully logged."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @exercise = Exercise.joins(:exercise_type).where(exercise_types: { user_id: current_user.id }).find(params[:id])
    @exercise_types = current_user.exercise_types.order(:name)

    if @exercise.update(exercise_params.except(:performed_at))
      @exercise.activity_log.update(performed_at: params[:exercise][:performed_at]) if params[:exercise][:performed_at].present?
      redirect_to safe_return_to.presence || activity_path, notice: "Exercise was successfully updated."
    else
      @return_to = safe_return_to
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    exercise = Exercise.joins(:exercise_type).where(exercise_types: { user_id: current_user.id }).find(params[:id])
    exercise.destroy
    redirect_to safe_return_to.presence || activity_path, notice: "Activity was successfully deleted.", status: :see_other
  end

  private

  def exercise_params
    params.require(:exercise).permit(:value, :notes, :performed_at, :added_weight, :rpe, :reps)
  end
end
