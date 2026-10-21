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
end
