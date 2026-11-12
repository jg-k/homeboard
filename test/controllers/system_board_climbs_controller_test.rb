require "test_helper"

class SystemBoardClimbsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @system_board_climb = SystemBoardClimb.create!(
      uuid: "boardsesh-kilter-abc-2025-06-15T10:00:00.000Z",
      board: "boardsesh_kilter",
      climb_name: "Test Climb",
      climbed_at: Time.current
    )
    @system_board_climb.create_activity_log!(user: @user, performed_at: @system_board_climb.climbed_at)
  end

  test "DELETE destroy removes climb and activity log" do
    sign_in @user

    assert_difference [ "SystemBoardClimb.count", "ActivityLog.count" ], -1 do
      delete system_board_climb_url(@system_board_climb)
    end

    assert_redirected_to activity_path
  end

  test "DELETE destroy requires authentication" do
    delete system_board_climb_url(@system_board_climb)
    assert_redirected_to new_user_session_path
  end

  test "cannot delete other users climbs" do
    sign_in users(:two)

    assert_no_difference "SystemBoardClimb.count" do
      delete system_board_climb_url(@system_board_climb)
    end

    assert_response :not_found
  end
end
