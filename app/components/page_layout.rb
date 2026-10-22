class PageLayout < Phlex::HTML
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::LinkTo

  SIZES = { default: "page", sm: "page-sm" }.freeze

  # actions is markup for the buttons beside the title, built with Rails
  # helpers so it arrives html_safe, as in
  #
  #   actions: link_to("New Metric", new_metric_path, class: "btn btn-primary")
  def initialize(title:, subtitle: nil, size: :default, back_to: nil, back_label: "Back", actions: nil)
    @title = title
    @subtitle = subtitle
    @size = size
    @back_to = back_to
    @back_label = back_label
    @actions = actions
  end

  def view_template
    content_for(:title) { @title }
    div(class: SIZES.fetch(@size)) do
      div(class: "mb-6") { link_to "← #{@back_label}", @back_to } if @back_to
      if @actions
        div(class: "page-header page-header-flex") do
          div { heading }
          div(class: "page-header-actions") { raw(@actions) }
        end
      else
        div(class: "page-header") { heading }
      end
      yield
    end
  end

  private

  def heading
    h1(class: "page-title") { @title }
    p(class: "page-subtitle") { @subtitle } if @subtitle
  end
end
