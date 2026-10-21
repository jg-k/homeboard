require "test_helper"

class StatsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:one) }

  test "defaults to three months, counted per week" do
    get stats_path

    assert_response :success
    assert_select ".period-picker-active", "3 months"
    assert_select "h2", "Climbing attempts and sends per week"
  end

  test "the period picker switches to a year, counted per month" do
    get stats_path(period: "1y")

    assert_select ".period-picker-active[aria-current=true]", "1 year"
    assert_select "h2", "Climbing attempts and sends per month"
  end

  test "each option keeps the overview tab" do
    get stats_path

    Charts::Period::PRESETS.each_key do |key|
      assert_select ".period-picker a[href=?]", stats_path(tab: "overview", period: key)
    end
  end

  test "an unknown period falls back to the default" do
    get stats_path(period: "forever")

    assert_response :success
    assert_select ".period-picker-active", "3 months"
  end

  test "the overview shows a grade pyramid per board with sends in the period" do
    problem = board_layouts(:one).problems.create!(name: "Crimpy", grade: "V5", start_holds: [ { x: 0.1, y: 0.1 } ])
    problem.board_climbs.create!(climb_type: "sent", climbed_at: 1.day.ago)
           .create_activity_log!(user: users(:one), performed_at: 1.day.ago)

    get stats_path

    assert_select "h2", "Sends by grade"
    assert_select ".grade-pyramid h3", boards(:one).name
  end

  test "with no sends in the period there is no pyramid card" do
    get stats_path(period: "4w")

    assert_select "h2", text: "Sends by grade", count: 0
  end
end
