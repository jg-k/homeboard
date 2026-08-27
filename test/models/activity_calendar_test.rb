require "test_helper"

class ActivityCalendarTest < ActiveSupport::TestCase
  setup do
    @user = users(:two)
    @ascent_day = 2.weeks.ago.to_date
    @hike_day = 3.weeks.ago.to_date

    CragAscent.create!(route_name: "Magic Flute", ascent_type: "redpoint", ascent_date: @ascent_day)
      .create_activity_log!(user: @user, performed_at: @ascent_day.noon)
    Hike.create!(name: "Ben Nevis")
      .create_activity_log!(user: @user, performed_at: @hike_day.noon)
  end

  def summary(**options)
    ActivityCalendar.new(@user, **options).summary_by_date
  end

  test "counts every category by default" do
    assert_equal [ @hike_day, @ascent_day ].sort, summary.keys.sort
  end

  test "a category leaves the other days out of the calendar entirely" do
    days = summary(category: :crag_ascent)

    assert_equal [ @ascent_day ], days.keys
    assert_equal :crag_ascent, days[@ascent_day].dominant_category
  end

  # A day that has both should take its colour from the category being filtered
  # on, not from whichever scores highest overall.
  test "a filtered day is coloured by the category asked for" do
    Hike.create!(name: "Second wind")
      .create_activity_log!(user: @user, performed_at: @ascent_day.noon)

    assert_equal :crag_ascent, summary[@ascent_day].dominant_category
    assert_equal :hike, summary(category: :hike)[@ascent_day].dominant_category
  end

  test "an unknown category counts everything" do
    assert_equal summary.keys.sort, summary(category: :nonsense).keys.sort
  end

  test "each category caches separately" do
    assert_equal 1, summary(category: :crag_ascent).size
    assert_equal 1, summary(category: :hike).size
    assert_equal 2, summary.size
  end

  test "category rejects anything that is not one" do
    assert_equal :hike, ActivityCalendar.category("hike")
    assert_nil ActivityCalendar.category("nonsense")
    assert_nil ActivityCalendar.category(nil)
    assert_nil ActivityCalendar.category("")
  end
end
