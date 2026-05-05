class ExerciseCard < ActivityCard
  def initialize(buddy: nil, **)
    @buddy = buddy
    super(**)
  end

  private

  def exercise = loggable
  def kind = :exercise
  def badge_color = :teal
  def badge_label = "Exercise"

  def render_header
    span(class: "activity-title") { exercise.name }
    span(class: "text-lg font-medium text-teal") { exercise_summary }
    link_to chart_path,
      class: "btn-icon",
      title: "View exercise history",
      data: { turbo_frame: "_top" } do
      icon(:bar_chart)
    end
  end

  def render_meta
    span { smart_date(@activity_log.performed_at) }
  end

  def notes = exercise.notes

  def activity_actions
    @activity_actions ||= ActivityActions.new(
      edit_path: edit_exercise_path(exercise),
      delete_path: exercise_path(exercise),
      delete_confirm: "Are you sure you want to delete this activity?",
      primary_action: {
        path: new_exercise_path(
          exercise_type_id: exercise.exercise_type_id,
          value: exercise.value,
          added_weight: exercise.added_weight,
          reps: exercise.effective_reps,
          category: exercise.exercise_type.category
        ),
        title: "Duplicate to today",
        icon: :copy
      }
    )
  end

  def chart_path
    if @buddy
      exercise_chart_buddy_path(@buddy, exercise_type_id: exercise.exercise_type_id)
    else
      exercise_type_path(exercise.exercise_type)
    end
  end

  def exercise_summary
    parts = +"#{exercise.value} #{exercise.unit}"
    parts << " × #{exercise.effective_reps} reps" if exercise.effective_reps.present?
    parts << ", + #{exercise.added_weight.to_i}kg" if exercise.added_weight.present?
    parts << " @ RPE #{exercise.rpe}" if exercise.rpe.present?
    parts << ", #{exercise.rest_seconds}s rest" if exercise.rest_seconds.present?
    parts
  end
end
