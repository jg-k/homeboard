require "test_helper"

class LogActivityTabsTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:one) }

  {
    exercise: [ :new_exercise_path, "Exercise" ],
    gym_session: [ :new_gym_session_path, "Indoor Climbing" ],
    hike: [ :new_hike_path, "Hike" ]
  }.each do |kind, (path, label)|
    test "the #{kind} page marks its own tab active" do
      get public_send(path)

      assert_response :success
      assert_select ".tabs a.tab", 3
      assert_select ".tabs a.tab.tab-active", 1
      assert_select ".tabs a.tab-active[href=?][data-turbo-action=replace]", public_send(path) do
        assert_select "svg.tab-icon"
        assert_select "span", label
      end
    end
  end
end
