class ExerciseTypes::TimersController < ApplicationController
  before_action :authenticate_user!

  # Counts down hangs and rests, then logs the set. The form starts from the
  # last set logged, so repeating a session is one tap.
  def show
    @exercise_type = current_user.exercise_types.find(params[:exercise_type_id])
    last = @exercise_type.exercises.joins(:activity_log).order("activity_logs.performed_at DESC").first
    @exercise = Exercise.new(exercise_type: @exercise_type,
                             value: last&.value,
                             reps: last&.reps || @exercise_type.reps,
                             added_weight: last&.added_weight)
  end
end
