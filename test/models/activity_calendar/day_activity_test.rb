require "test_helper"

class ActivityCalendar::DayActivityTest < ActiveSupport::TestCase
  def day(**categories)
    ActivityCalendar::DayActivity.new.tap do |d|
      categories.each { |category, (count, points)| d.add(category, count: count, points: points) }
    end
  end

  # Conditioning outscores a single board climb three to one, and used to take
  # the colour with it.
  test "a board day with conditioning on top is a board day" do
    assert_equal :board_climb, day(board_climb: [ 1, 1 ], exercise: [ 3, 3 ]).dominant_category
  end

  test "climbing outdoors outranks everything else" do
    assert_equal :crag_ascent, day(crag_ascent: [ 1, 4 ], gym_session: [ 1, 20 ], board_climb: [ 9, 9 ]).dominant_category
  end

  test "indoor outranks board" do
    assert_equal :gym_session, day(gym_session: [ 1, 1 ], board_climb: [ 8, 8 ]).dominant_category
  end

  test "conditioning colours a day only when it is all there was" do
    assert_equal :exercise, day(exercise: [ 1, 1 ]).dominant_category
  end

  # Points still decide how dark the square is, across every category.
  test "intensity counts the whole day, not just the dominant category" do
    assert_equal 5, day(board_climb: [ 1, 1 ], exercise: [ 14, 14 ]).intensity
  end

  test "a session logged with no numbers still colours its day" do
    assert_equal :gym_session, day(gym_session: [ 1, 0 ]).dominant_category
  end

  test "an empty day has no colour" do
    assert_nil day.dominant_category
    assert_equal "grid-day", day.css_class
  end
end
