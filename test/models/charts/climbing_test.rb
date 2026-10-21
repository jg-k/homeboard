require "test_helper"

class Charts::ClimbingTest < ActiveSupport::TestCase
  setup do
    @user = users(:two)
    travel_to Time.zone.local(2026, 10, 21, 12)
  end

  def log(loggable, at)
    loggable.create_activity_log!(user: @user, performed_at: at)
  end

  def series(key) = Charts::Climbing.new(@user, period: Charts::Period.find(key)).series.index_by { _1[:name] }

  test "counts each source into the week it happened in" do
    log(CragAscent.create!(route_name: "Magic Flute", ascent_type: "redpoint", ascent_date: Date.new(2026, 10, 20)),
        Time.zone.local(2026, 10, 20, 12))
    log(GymSession.create!(number_of_boulders: 6, number_of_circuits: 2), Time.zone.local(2026, 10, 13, 19))

    data = series("4w")

    assert_equal [ [ "Sep 28", 0 ], [ "Oct 05", 0 ], [ "Oct 12", 0 ], [ "Oct 19", 1 ] ], data["Outdoor"][:data]
    assert_equal 8, data["Indoor Climbing"][:data].to_h["Oct 12"]
  end

  test "leaves out anything older than the period" do
    log(GymSession.create!(number_of_boulders: 5), Time.zone.local(2026, 8, 3, 19))

    assert_equal 0, series("4w")["Indoor Climbing"][:data].sum(&:last)
    assert_equal 5, series("3m")["Indoor Climbing"][:data].sum(&:last)
  end

  test "a year is grouped by month" do
    log(GymSession.create!(number_of_boulders: 4), Time.zone.local(2026, 3, 2, 19))
    log(GymSession.create!(number_of_boulders: 3), Time.zone.local(2026, 3, 28, 19))

    assert_equal 7, series("1y")["Indoor Climbing"][:data].to_h["Mar 2026"]
  end
end
