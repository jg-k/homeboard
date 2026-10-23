require "test_helper"

class ExerciseType::BodyweightRatioTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @hang = @user.exercise_types.create!(name: "Max hang", unit: "seconds", added_weight_possible: true, reps: 5)
    @weight = @user.metrics.create!(name: "Body weight", unit: "kg", body_weight: true)
  end

  def weigh(kg, at) = @weight.measurements.create!(value: kg, recorded_at: at)
  def hang(added, at, value: 10, reps: nil) = @hang.exercises.create!(value: value, reps: reps, added_weight: added, performed_at: at)
  def ratio = ExerciseType::BodyweightRatio.new(@hang, @weight)

  test "adds the added weight to the body weight in force at each set" do
    weigh(80, Time.zone.local(2026, 9, 1))
    weigh(75, Time.zone.local(2026, 10, 1))
    hang(20, Time.zone.local(2026, 9, 15))
    hang(15, Time.zone.local(2026, 10, 15))

    assert_equal [ { name: "10 seconds × 5 reps", data: [ [ "2026-09-15", 125.0 ], [ "2026-10-15", 120.0 ] ] } ], ratio.chart_data
  end

  test "a set before any weigh-in uses the first one, and no added weight is 100%" do
    hang(nil, Time.zone.local(2026, 8, 1))
    weigh(80, Time.zone.local(2026, 9, 1))

    assert_equal [ [ "2026-08-01", 100.0 ] ], ratio.chart_data.first[:data]
  end

  test "different durations and reps are separate lines" do
    weigh(80, Time.zone.local(2026, 9, 1))
    hang(20, Time.zone.local(2026, 9, 2))
    hang(10, Time.zone.local(2026, 9, 3), value: 7.5, reps: 6)

    assert_equal [ "10 seconds × 5 reps", "7.5 seconds × 6 reps" ], ratio.chart_data.pluck(:name)
  end

  test "nothing to plot without a weigh-in" do
    hang(20, Time.zone.local(2026, 9, 2))

    assert_empty ratio.chart_data
  end
end
