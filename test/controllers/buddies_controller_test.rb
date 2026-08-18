require "test_helper"

class BuddiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other = users(:two)
    @other.update!(allow_follows: true)
    sign_in @user
  end

  test "follows a climber by display name" do
    assert_difference "Follow.count", 1 do
      post buddies_url, params: { display_name: @other.display_name }
    end

    assert_redirected_to buddies_path
    assert @user.following?(@other)
  end

  test "matches the display name regardless of case or padding" do
    post buddies_url, params: { display_name: "  #{@other.display_name.upcase}  " }

    assert @user.following?(@other)
  end

  test "reports an unknown display name" do
    assert_no_difference "Follow.count" do
      post buddies_url, params: { display_name: "nobody" }
    end

    assert_equal "No climber found with that display name.", flash[:alert]
  end

  test "requires a display name" do
    post buddies_url, params: { display_name: "" }

    assert_equal "Please enter a display name.", flash[:alert]
  end

  test "will not follow a climber who has not enabled followers" do
    @other.update!(allow_follows: false)

    assert_no_difference "Follow.count" do
      post buddies_url, params: { display_name: @other.display_name }
    end
    assert_equal "This user doesn't allow followers.", flash[:alert]
  end

  test "index identifies climbers by display name, not email" do
    @user.follow(@other)
    get buddies_url

    assert_response :success
    assert_select "input[name='display_name']"
    assert_match @other.display_name, response.body
    assert_no_match(/#{Regexp.escape(@other.email)}/, response.body)
  end

  test "a buddy's activity page is titled by display name" do
    @user.follow(@other)
    get activity_buddy_url(@other)

    assert_response :success
    assert_match @other.display_name, response.body
    assert_no_match(/#{Regexp.escape(@other.email)}/, response.body)
  end
end
