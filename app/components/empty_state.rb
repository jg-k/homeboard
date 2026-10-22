class EmptyState < Phlex::HTML
  def initialize(title:, description: nil)
    @title = title
    @description = description
  end

  def view_template(&actions)
    div(class: "empty-state") do
      h3 { @title }
      p { @description } if @description
      div(class: "empty-state-actions", &actions) if actions
    end
  end
end
