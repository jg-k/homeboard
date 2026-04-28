class PageLayout < Phlex::HTML
  include Phlex::Rails::Helpers::ContentFor

  def initialize(title:, subtitle: nil)
    @title = title
    @subtitle = subtitle
  end

  def view_template
    content_for(:title) { @title }
    div(class: "page") do
      div(class: "page-header") do
        h1(class: "page-title") { @title }
        p(class: "page-subtitle") { @subtitle } if @subtitle
      end
      yield
    end
  end
end
