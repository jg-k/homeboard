require "test_helper"

class ActivityControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:two)
    @ascent_day = 2.weeks.ago.to_date
    @hike_day = 3.weeks.ago.to_date

    log(CragAscent.create!(route_name: "Magic Flute", ascent_type: "redpoint",
                           ascent_date: @ascent_day), @ascent_day)
    log(Hike.create!(name: "Ben Nevis"), @hike_day)

    sign_in @user
  end

  def log(loggable, date)
    loggable.create_activity_log!(user: @user, performed_at: date.noon)
  end

  test "shows every category by default" do
    get activity_url

    assert_response :success
    assert_match "Magic Flute", response.body
    assert_match "Ben Nevis", response.body
  end

  test "a category filters the list down to it" do
    get activity_url(category: "crag_ascent")

    assert_response :success
    assert_match "Magic Flute", response.body
    assert_no_match(/Ben Nevis/, response.body)
  end

  # The grid is the point of the filter: a day with no ascent on it should stop
  # being a filled square, not just drop out of the list.
  test "a category filters the grid down to its own days" do
    get activity_url(category: "crag_ascent")

    assert_select "a[href=?]", activity_day_path(date: @ascent_day.iso8601)
    assert_select "a[href=?]", activity_day_path(date: @hike_day.iso8601), count: 0
  end

  test "the legend links to each category and back to all" do
    get activity_url

    assert_select "a.legend-item[href=?]", activity_path(category: "crag_ascent")
    assert_select "a.legend-item[href=?]", activity_path, text: "All"
  end

  test "the filter in force is marked active" do
    get activity_url(category: "hike")

    assert_select "a.legend-filter-active[href=?]", activity_path(category: "hike")
  end

  test "a category nobody has logged says so rather than looking broken" do
    get activity_url(category: "gym_session")

    assert_response :success
    assert_match "No indoor activity yet", response.body
  end

  # A hand-edited query param should not empty the page.
  test "an unknown category falls back to everything" do
    get activity_url(category: "nonsense")

    assert_response :success
    assert_select "a.legend-filter-active[href=?]", activity_path, text: "All"
    assert_match "Magic Flute", response.body
    assert_match "Ben Nevis", response.body
  end

  test "the history legend filters its grids down to one category" do
    get activity_history_url(category: "crag_ascent")

    assert_response :success
    assert_select "a.legend-filter-active[href=?]", activity_history_path(category: "crag_ascent")
    assert_select "a[href=?]", activity_day_path(date: @ascent_day.iso8601)
    assert_select "a[href=?]", activity_day_path(date: @hike_day.iso8601), count: 0
  end

  test "the history legend links back to all" do
    get activity_history_url

    assert_select "a.legend-filter-active[href=?]", activity_history_path, text: "All"
    assert_select "a.legend-item[href=?]", activity_history_path(category: "hike")
  end

  test "requires authentication" do
    sign_out @user
    get activity_url

    assert_redirected_to new_user_session_path
  end
end
