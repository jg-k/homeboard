require "test_helper"

class TrackingCardsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @exercise_type = @user.exercise_types.order(:name).first
    @metric = @user.metrics.create!(name: "Body weight", unit: "kg")
  end

  test "an exercise type card links to its chart and edits back to the tracking tab" do
    get tracking_path(tab: "exercises", category: @exercise_type.category)

    return_to = tracking_path(tab: "exercises", category: @exercise_type.category)
    assert_select ".card h2", @exercise_type.name
    assert_select "a[href=?]", exercise_type_path(@exercise_type)
    assert_select "a[href=?]", edit_exercise_type_path(@exercise_type, return_to: return_to)
  end

  test "targets are listed under the exercise type they belong to" do
    target = @exercise_type.targets.create!(value: 30, applicable_from: Date.new(2026, 1, 5))

    get tracking_path(tab: "exercises", category: @exercise_type.category)

    assert_match "30.0 #{@exercise_type.unit} from Jan 05, 2026", response.body
    assert_select "form[action=?] button[title='Delete target']", exercise_type_target_path(@exercise_type, target)
    assert_select "form.target-form[action=?]", exercise_type_targets_path(@exercise_type)
  end

  test "a metric card shows the latest measurement and nests its targets under the metric" do
    @metric.measurements.create!(value: 71, recorded_at: 2.days.ago)
    @metric.measurements.create!(value: 70, recorded_at: 1.day.ago)
    target = @metric.targets.create!(value: 68, applicable_from: Date.current)

    get tracking_path(tab: "metrics")

    assert_select ".card h2 a[href=?]", metric_path(@metric), text: "Body weight"
    assert_select ".card span.ml-3", text: "Latest: 70.0 kg"
    assert_select "form.measurement-form[action=?]", metric_measurements_path(@metric)
    assert_select "form[action=?] button[title='Delete target']", metric_target_path(@metric, target)
    assert_select "form.target-form[action=?]", metric_targets_path(@metric)
  end

  test "the metrics index renders the same cards" do
    get metrics_path

    assert_response :success
    assert_select ".card h2 a[href=?]", metric_path(@metric)
    assert_select "form.target-form[action=?]", metric_targets_path(@metric)
  end
end
