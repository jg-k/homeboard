require "test_helper"

class ProgressChartsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @metric = @user.metrics.create!(name: "Body weight", unit: "kg")
    @metric.measurements.create!(value: 70, recorded_at: 2.days.ago)
  end

  test "a metric chart defaults to every log over all time" do
    get metric_path(@metric)

    assert_select ".progress-controls .period-picker-active", 2
    assert_select ".period-picker-active", "All"
    assert_select ".period-picker-active", "Every log"
    assert_select ".period-picker a[href=?]", metric_path(@metric, range: "3m", grouping: "each")
  end

  test "picking a grouping keeps the range" do
    get metric_path(@metric, range: "6m", grouping: "week")

    assert_select ".period-picker-active", "6 months"
    assert_select ".period-picker-active", "Weekly average"
    assert_select ".period-picker a[href=?]", metric_path(@metric, range: "6m", grouping: "day")
  end

  test "an exercise type chart has the same controls" do
    exercise_type = @user.exercise_types.first

    get exercise_type_path(exercise_type, range: "1y")

    assert_response :success
    assert_select ".period-picker-active", "1 year"
  end

  test "the fitness tab applies one choice to every chart in the category" do
    exercise_type = @user.exercise_types.first

    get stats_path(tab: "fitness", category: exercise_type.category, range: "1m")

    assert_response :success
    assert_select ".period-picker-active", "1 month"
    assert_select ".period-picker a[href=?]",
                  stats_path(tab: "fitness", category: exercise_type.category, range: "1m", grouping: "week")
  end
end
