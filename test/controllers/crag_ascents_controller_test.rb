require "test_helper"

class CragAscentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @crag_ascent = CragAscent.create!(
      route_name: "Test Route",
      ascent_date: Time.current,
      ascent_type: "redpoint",
      gear_style: "sport"
    )
    @crag_ascent.create_activity_log!(user: @user, performed_at: @crag_ascent.ascent_date)
  end

  test "DELETE destroy removes ascent and activity log" do
    sign_in @user

    assert_difference [ "CragAscent.count", "ActivityLog.count" ], -1 do
      delete crag_ascent_url(@crag_ascent)
    end

    assert_redirected_to activity_path
  end

  test "DELETE destroy requires authentication" do
    delete crag_ascent_url(@crag_ascent)
    assert_redirected_to new_user_session_path
  end

  test "cannot delete other users ascents" do
    sign_in users(:two)

    assert_no_difference "CragAscent.count" do
      delete crag_ascent_url(@crag_ascent)
    end

    assert_response :not_found
  end
end
