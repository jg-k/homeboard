require "test_helper"

# Every tab row in the app is a TabBar (or the ActivityTypeTabs that share its
# look), so they all render as nav.tabs with a.tab links.
class TabBarsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "stats has its sections as tabs and fitness categories as a second row" do
    get stats_path(tab: "fitness")

    assert_select "nav.tabs:not(.tabs-secondary) a.tab-active[aria-current=page]", "Fitness"
    assert_select "nav.tabs.tabs-secondary a.tab", minimum: 1
    assert_select ".tab-link", false
  end

  test "tracking has its sections as tabs and exercise categories as a second row" do
    get tracking_path(tab: "exercises")

    assert_select "nav.tabs:not(.tabs-secondary) a.tab-active", "Exercises"
    assert_select "nav.tabs.tabs-secondary a.tab-active", 1
  end

  test "the problems page switches boards with tabs that stay in history" do
    get board_problems_path(boards(:one))

    assert_select "nav.tabs[aria-label=Boards] a.tab-active", boards(:one).name
    assert_select "nav.tabs[aria-label=Boards] a[data-turbo-action]", false
  end

  test "activity comments filter by category with tabs" do
    get activity_comments_path

    assert_select "nav.tabs a.tab-active", "All"
  end

  test "the log activity switcher shares the tab markup" do
    get new_hike_path

    assert_select "nav.tabs[aria-label='Activity type'] a.tab-active[aria-current=page]", text: /Hike/
  end
end
