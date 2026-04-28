class SettingsSection < Phlex::HTML
  def initialize(title:)
    @title = title
  end

  def view_template(&)
    section(class: "settings-section") do
      h2(class: "settings-section-title") { @title }
      div(class: "card", &)
    end
  end
end
