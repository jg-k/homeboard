class MetricCard < ApplicationComponent
  def initialize(metric:)
    @metric = metric
  end

  def view_template
    div(class: "card") do
      div(class: "flex-between") do
        div do
          h2(class: "text-xl font-semibold") { link_to @metric.name, metric_path(@metric) }
          p(class: "text-gray mt-1") do
            plain "Unit: "
            span(class: "font-medium") { @metric.unit }
            if (latest = @metric.measurements.order(recorded_at: :desc).first)
              span(class: "ml-3") do
                plain "Latest: "
                span(class: "font-medium") { "#{latest.value} #{@metric.unit}" }
              end
            end
          end
        end
        render_actions
      end
      render_measurement_form
      render TargetList.new(targetable: @metric)
    end
  end

  private

  def render_actions
    div(class: "flex gap-2") do
      link_to metric_path(@metric), class: "icon-link", title: "View Chart" do
        icon(:bar_chart, size: :sm)
      end
      link_to edit_metric_path(@metric), class: "icon-link", title: "Edit" do
        icon(:edit, size: :sm)
      end
      button_to @metric, method: :delete, data: { turbo_confirm: "Are you sure? This will delete all measurements." },
                class: "icon-link icon-link-danger", title: "Delete" do
        icon(:trash, size: :sm)
      end
    end
  end

  def render_measurement_form
    div(class: "mt-4") do
      p(class: "text-sm text-muted mb-2") { "Log measurement:" }
      form_with url: metric_measurements_path(@metric), scope: :measurement, method: :post, class: "measurement-form" do |f|
        f.number_field :value, step: :any, class: "form-input form-input-sm", placeholder: "Value", required: true
        label(class: "measurement-form-date") do
          span(class: "text-sm text-muted") { "Date:" }
          f.datetime_local_field :recorded_at, value: Time.current.strftime("%Y-%m-%dT%H:%M"), class: "form-input form-input-sm"
        end
        f.submit "Log", class: "btn btn-secondary btn-sm"
      end
    end
  end
end
