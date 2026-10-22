require "test_helper"

class PageHeadersTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:one) }

  test "the metrics index offers New Metric beside its title" do
    get metrics_path

    assert_select "title", "Metrics"
    assert_select ".page-header-flex h1.page-title", "Metrics"
    assert_select ".page-header-actions a.btn-primary[href=?]", new_metric_path, text: "New Metric"
  end

  test "the activity log links to stats with the bar chart icon" do
    get activity_path

    assert_select ".page-header-actions a.btn-icon[href=?][title=Stats] svg", stats_path
  end

  test "pages without actions use the plain header" do
    get tracking_path

    assert_select ".page-header h1.page-title", "Tracking"
    assert_select ".page-header-actions", false
  end

  test "log activity and comment pages use the narrow layout" do
    get new_hike_path
    assert_select ".page-sm .page-header h1", "Log Activity"
    assert_select "title", "Log Activity"
  end
end
