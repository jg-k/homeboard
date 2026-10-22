class PageLayout < Phlex::HTML
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::LinkTo

  SIZES = { default: "page", sm: "page-sm" }.freeze

  def initialize(title:, subtitle: nil, size: :default, back_to: nil, back_label: "Back")
    @title = title
    @subtitle = subtitle
    @size = size
    @back_to = back_to
    @back_label = back_label
  end

  def view_template
    content_for(:title) { @title }
    div(class: SIZES.fetch(@size)) do
      div(class: "mb-6") { link_to "← #{@back_label}", @back_to } if @back_to
      div(class: "page-header") do
        h1(class: "page-title") { @title }
        p(class: "page-subtitle") { @subtitle } if @subtitle
      end
      yield
    end
  end
end
