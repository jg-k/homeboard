require "test_helper"

class Charts::ProgressTest < ActiveSupport::TestCase
  setup do
    @today = Date.new(2026, 10, 21)
    @metric = users(:one).metrics.create!(name: "Body weight", unit: "kg")
  end

  def measure(value, on) = @metric.measurements.create!(value: value, recorded_at: on.to_time.change(hour: 8))
  def target(value, from) = @metric.targets.create!(value: value, applicable_from: from)

  def progress(range: nil, grouping: nil)
    Charts::Progress.new(@metric, choice: Charts::Progress::Choice.from(range: range, grouping: grouping), today: @today)
  end

  def line(progress, name = "Body weight") = progress.series.find { _1[:name] == name }[:data]

  test "plots every log over all time by default" do
    measure(72, Date.new(2025, 1, 10))
    measure(70, Date.new(2026, 10, 1))

    assert_equal [ [ "2025-01-10", 72.0 ], [ "2026-10-01", 70.0 ] ], line(progress)
    assert_not progress.target?
  end

  test "a range leaves out logs from before it" do
    measure(72, Date.new(2026, 6, 1))
    measure(70, Date.new(2026, 10, 1))

    assert_equal [ [ "2026-10-01", 70.0 ] ], line(progress(range: "1m"))
    assert_equal 2, line(progress(range: "6m")).size
  end

  test "a range with nothing in it has no data" do
    measure(72, Date.new(2026, 1, 1))

    assert_not progress(range: "1m").any?
  end

  test "daily and weekly averages merge the logs that fall together" do
    measure(70, Date.new(2026, 10, 19))
    measure(71, Date.new(2026, 10, 19))
    measure(73, Date.new(2026, 10, 21))

    assert_equal [ [ "2026-10-19", 70.5 ], [ "2026-10-21", 73.0 ] ], line(progress(grouping: "day"))
    assert_equal [ [ "2026-10-19", 71.33 ] ], line(progress(grouping: "week"))
  end

  test "unknown choices fall back to every log, all time" do
    choice = Charts::Progress::Choice.from(range: "forever", grouping: "best")

    assert_equal({ range: "all", grouping: "each" }, choice.to_h)
  end

  test "the target line starts at the first plotted point, with the target in force then" do
    measure(72, Date.new(2026, 6, 1))
    measure(70, Date.new(2026, 10, 1))
    target(71, Date.new(2026, 1, 1))
    target(69, Date.new(2026, 10, 10))

    assert_equal [
      [ "2026-10-01T00:00:00Z", 71.0 ],
      [ "2026-10-09T23:59:00Z", 71.0 ],
      [ "2026-10-10T00:00:00Z", 69.0 ],
      [ "2026-10-21T23:59:59Z", 69.0 ]
    ], line(progress(range: "1m"), "Target")
  end

  test "over all time the first target reaches back to the first log" do
    measure(72, Date.new(2026, 3, 1))
    target(70, Date.new(2026, 5, 1))

    assert_equal [ "2026-03-01T00:00:00Z", 70.0 ], line(progress, "Target").first
  end

  test "targets that have not started yet are not drawn" do
    measure(72, Date.new(2026, 10, 1))
    target(65, Date.new(2026, 12, 1))

    assert_not progress.target?
  end

  test "keeps one line per added weight for an exercise type" do
    exercise_type = users(:one).exercise_types.create!(name: "Pull-up", unit: "reps", added_weight_possible: true)
    [ [ 8, nil ], [ 5, 10 ] ].each do |value, weight|
      exercise_type.exercises.create!(value: value, added_weight: weight)
                   .create_activity_log!(user: users(:one), performed_at: Time.zone.local(2026, 10, 20, 18))
    end

    names = Charts::Progress.new(exercise_type, today: @today).series.map { _1[:name] }

    assert_equal [ "Bodyweight", "+10kg" ], names
  end
end
