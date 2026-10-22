# Lists the targets set on an exercise type or metric, with a form to add
# another. Both nest their targets under themselves in the routes, so the
# paths come from the targetable.
class TargetList < ApplicationComponent
  def initialize(targetable:)
    @targetable = targetable
  end

  def view_template
    div(class: "mt-4") do
      p(class: "text-sm text-muted mb-2") { "Targets:" }
      targets = @targetable.targets.reorder(applicable_from: :asc).to_a
      if targets.any?
        div(class: "stack-sm mb-3") do
          targets.each { |target| render_target(target) }
        end
      end
      render_form
    end
  end

  private

  def render_target(target)
    div(class: "flex-between text-sm") do
      span { "#{target.value} #{@targetable.unit} from #{target.applicable_from.to_date.strftime("%b %d, %Y")}" }
      button_to [ @targetable, target ], method: :delete,
                data: { turbo_confirm: "Delete this target?" },
                class: "icon-link icon-link-danger", title: "Delete target" do
        icon(:trash, size: :sm)
      end
    end
  end

  def render_form
    form_with url: [ @targetable, :targets ], scope: :target, method: :post, class: "target-form" do |f|
      f.number_field :value, step: :any, class: "form-input form-input-sm target-form-value", placeholder: "Value"
      label(class: "target-form-date") do
        span(class: "text-sm text-muted") { "From:" }
        f.date_field :applicable_from, value: Date.current, class: "form-input form-input-sm"
      end
      f.submit "Add", class: "btn btn-secondary btn-sm"
    end
  end
end
