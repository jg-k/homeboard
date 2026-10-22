require "test_helper"

class Charts::PeriodTest < ActiveSupport::TestCase
  def period(key, today: Date.new(2026, 10, 21)) = Charts::Period.new(key, today: today)

  test "weekly periods end on the current week and label each bar by its Monday" do
    buckets = period("4w").buckets

    assert_equal [ "Sep 28", "Oct 05", "Oct 12", "Oct 19" ], buckets.map(&:label)
    assert_equal Date.new(2026, 10, 19), buckets.last.start
  end

  test "each preset has a fixed number of bars" do
    assert_equal({ "4w" => 4, "3m" => 13, "6m" => 26, "1y" => 12 },
                 Charts::Period::PRESETS.keys.index_with { period(_1).buckets.size })
  end

  test "a year is counted per month" do
    buckets = period("1y").buckets

    assert_equal :month, period("1y").bucket
    assert_equal "Nov 2025", buckets.first.label
    assert_equal "Oct 2026", buckets.last.label
  end

  test "starts at midnight on the first bar" do
    assert_equal Time.zone.local(2026, 9, 28), period("4w").starts_at
  end

  test "an unknown key falls back to the default" do
    assert_equal Charts::Period::DEFAULT, Charts::Period.find("forever").key
    assert_equal Charts::Period::DEFAULT, Charts::Period.find(nil).key
  end

  test "totals fill every bar, with zeros where nothing happened" do
    rows = [
      [ Time.zone.local(2026, 10, 19, 18), 2 ],
      [ Time.zone.local(2026, 10, 25, 23), 3 ],
      [ Time.zone.local(2026, 10, 5, 9), 1 ]
    ]

    assert_equal [ [ "Sep 28", 0 ], [ "Oct 05", 1 ], [ "Oct 12", 0 ], [ "Oct 19", 5 ] ], period("4w").totals(rows)
  end

  # The days before a year's first Monday used to land in a "week 00" bucket
  # that no bar matched, so they never showed up.
  test "a week that straddles new year keeps the days from both years" do
    p = period("4w", today: Date.new(2026, 1, 14))
    rows = [ [ Time.zone.local(2025, 12, 30), 1 ], [ Time.zone.local(2026, 1, 2), 1 ] ]

    assert_includes p.totals(rows), [ "Dec 29", 2 ]
  end
end
