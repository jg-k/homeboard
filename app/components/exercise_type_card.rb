class ExerciseTypeCard < ApplicationComponent
  def initialize(exercise_type:, return_to: nil)
    @exercise_type = exercise_type
    @return_to = return_to
  end

  def view_template
    div(class: "card") do
      div(class: "flex-between") do
        div do
          h2(class: "text-xl font-semibold") { @exercise_type.name }
          p(class: "text-gray mt-1") do
            plain "Unit: "
            span(class: "font-medium") { @exercise_type.unit }
            plain " · #{@exercise_type.reps} reps" if @exercise_type.reps.present?
            plain " · #{@exercise_type.rest_seconds}s rest" if @exercise_type.rest_seconds.present?
          end
        end
        render_actions
      end
      render TargetList.new(targetable: @exercise_type)
    end
  end

  private

  def render_actions
    div(class: "flex gap-2") do
      link_to exercise_type_path(@exercise_type), class: "icon-link", title: "Chart & Logs" do
        icon(:bar_chart, size: :sm)
      end
      link_to edit_exercise_type_path(@exercise_type, return_to: @return_to), class: "icon-link", title: "Edit" do
        icon(:edit, size: :sm)
      end
      button_to @exercise_type, method: :delete, data: { turbo_confirm: "Are you sure?" },
                class: "icon-link icon-link-danger", title: "Delete" do
        icon(:trash, size: :sm)
      end
    end
  end
end
