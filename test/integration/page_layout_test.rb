require "test_helper"

class PageLayoutTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "a form page is narrow, titled, and links back" do
    get new_board_path

    assert_select "title", "New Board"
    assert_select ".page-sm > .mb-6 > a[href=?]", boards_path, text: "← Back to Boards"
    assert_select ".page-sm .page-header h1.page-title", "New Board"
    assert_select ".page-sm .card form"
  end

  test "the back link defaults to plain Back" do
    get edit_exercise_type_path(@user.exercise_types.first)

    assert_select ".page-sm > .mb-6 > a", text: "← Back"
  end

  test "names in the back link and title are escaped" do
    metric = @user.metrics.create!(name: "<b>Weight</b>", unit: "kg")
    measurement = metric.measurements.create!(value: 70, recorded_at: Time.current)

    get edit_metric_measurement_path(metric, measurement)
    assert_select ".page-sm > .mb-6 > a b", false
    assert_select ".page-sm > .mb-6 > a[href=?]", metric_path(metric), text: "← Back to <b>Weight</b>"

    get edit_metric_path(metric)
    assert_select "h1.page-title b", false
    assert_select "h1.page-title", "Edit <b>Weight</b>"
  end
end
