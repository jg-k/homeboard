require "test_helper"

class TabBarTest < ActionView::TestCase
  def tabs(active:) = %w[One Two].map { TabBar::Tab.new(label: _1, url: "/#{_1.downcase}", active: _1 == active) }

  test "renders one link per tab, marking the active one" do
    html = render(TabBar.new(label: "Sections", tabs: tabs(active: "Two")))

    assert_includes html, %(<nav class="tabs" aria-label="Sections" data-controller="tabs">)
    assert_includes html, %(<a class="tab" data-turbo-action="replace" href="/one">One</a>)
    assert_includes html, %(<a class="tab tab-active" aria-current="page" data-turbo-action="replace" href="/two">Two</a>)
  end

  test "a nested row steps down a size" do
    assert_includes render(TabBar.new(label: "Categories", secondary: true, tabs: tabs(active: "One"))),
                    %(<nav class="tabs tabs-secondary")
  end

  test "replace: false keeps each tab in history" do
    assert_not_includes render(TabBar.new(label: "Boards", replace: false, tabs: tabs(active: "One"))), "turbo-action"
  end
end
