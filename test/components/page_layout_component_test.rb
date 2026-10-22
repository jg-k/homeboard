require "test_helper"

class PageLayoutComponentTest < ActionView::TestCase
  test "without actions the header is just the title and subtitle" do
    html = render(PageLayout.new(title: "Stats", subtitle: "This year")) { "body" }

    assert_includes html, %(<div class="page-header"><h1 class="page-title">Stats</h1><p class="page-subtitle">This year</p></div>)
  end

  test "actions sit beside the title" do
    html = render(PageLayout.new(title: "Metrics", actions: link_to("New Metric", "/metrics/new", class: "btn"))) { "body" }

    assert_includes html, %(<div class="page-header page-header-flex"><div><h1 class="page-title">Metrics</h1></div>)
    assert_includes html, %(<div class="page-header-actions"><a class="btn" href="/metrics/new">New Metric</a></div>)
  end

  # Text from a user must never become markup, so only Rails-built,
  # html_safe actions are accepted.
  test "actions that are not html_safe are refused" do
    assert_raises(Phlex::ArgumentError) do
      render(PageLayout.new(title: "Metrics", actions: "<script>alert(1)</script>")) { "body" }
    end
  end
end
