class Settings::GradingSystemsSection < ApplicationComponent
  def initialize(grading_systems:, current_user:)
    @grading_systems = grading_systems
    @current_user = current_user
  end

  def view_template
    section(class: "settings-section") do
      div(class: "flex justify-between items-center mb-4") do
        h2(class: "settings-section-title mb-0") { "Grading Systems" }
        link_to "New Grading System", new_grading_system_path, class: "btn btn-primary btn-sm"
      end

      if @grading_systems.any?
        div(class: "stack") do
          @grading_systems.each do |grading_system|
            render_grading_system(grading_system)
          end
        end
      else
        div(class: "empty-state") do
          h3 { "No grading systems found" }
          p { "Create a custom grading system for your gym." }
          div(class: "empty-state-actions") do
            link_to "New Grading System", new_grading_system_path, class: "btn btn-primary"
          end
        end
      end
    end
  end

  private

  def render_grading_system(grading_system)
    div(class: "card") do
      div(class: "flex justify-between items-start") do
        div do
          h3(class: "text-lg font-semibold") do
            plain grading_system.name
            if grading_system.system_type == "built_in"
              render Badge.new(:gray, class: "ml-2") { "Built-in" }
            end
            if @current_user.default_grading_system == grading_system
              render Badge.new(:green, class: "ml-2") { "Default" }
            end
          end
          p(class: "text-muted mt-1") do
            span(class: "font-medium") { grading_system.grades.size.to_s }
            plain " grades: "
            span(class: "text-sm") do
              plain grading_system.grades.first(5).join(", ")
              plain "..." if grading_system.grades.size > 5
            end
          end
        end
        div(class: "flex gap-2") do
          link_to "View", grading_system_path(grading_system), class: "btn-link"
          link_to "Edit", edit_grading_system_path(grading_system), class: "btn-link"
          if grading_system.system_type != "built_in"
            button_to "Delete", grading_system_path(grading_system), method: :delete, data: { turbo_confirm: "Are you sure?" }, class: "btn-link-danger"
          end
          unless @current_user.default_grading_system == grading_system
            button_to "Set as Default", set_as_default_grading_system_path(grading_system), method: :post, class: "btn-link-success"
          end
        end
      end
    end
  end
end
