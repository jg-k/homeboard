class SettingsRow < Phlex::HTML
  def initialize(title:, description: nil)
    @title = title
    @description = description
  end

  def view_template(&)
    div(class: "settings-row") do
      div(class: "settings-label") do
        span(class: "font-medium") { @title }
        p(class: "text-sm text-muted") { @description } if @description
      end
      div(class: "settings-value", &)
    end
  end
end
