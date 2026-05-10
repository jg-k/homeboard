require "test_helper"

class ActivityLogCommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @activity_log = activity_logs(:crag_ascent_one)
  end

  test "GET index requires authentication" do
    get activity_comments_url
    assert_redirected_to new_user_session_path
  end

  test "GET index lists user comments filtered by category" do
    sign_in @user
    @activity_log.comments.create!(body: "Watch loose hold", category: "safety")
    @activity_log.comments.create!(body: "Strong day", category: "obs")

    get activity_comments_url(category: "safety")
    assert_response :success
    assert_match "Watch loose hold", response.body
    assert_no_match "Strong day", response.body
  end

  test "GET index without category shows all" do
    sign_in @user
    @activity_log.comments.create!(body: "Watch loose hold", category: "safety")
    @activity_log.comments.create!(body: "Strong day", category: "obs")

    get activity_comments_url
    assert_response :success
    assert_match "Watch loose hold", response.body
    assert_match "Strong day", response.body
  end

  test "GET new requires the activity log to belong to current user" do
    sign_in @other_user
    get new_activity_log_comment_url(@activity_log)
    assert_response :not_found
  end

  test "POST create adds a comment" do
    sign_in @user
    assert_difference "ActivityLogComment.count", 1 do
      post activity_log_comments_url(activity_log_id: @activity_log.id),
           params: { activity_log_comment: { body: "Safety lapse on the crux", category: "safety" } }
    end
    assert_redirected_to activity_path
  end

  test "POST create rejects invalid category" do
    sign_in @user
    assert_no_difference "ActivityLogComment.count" do
      post activity_log_comments_url(activity_log_id: @activity_log.id),
           params: { activity_log_comment: { body: "x", category: "bogus" } }
    end
    assert_response :unprocessable_entity
  end

  test "POST create cannot target another user's activity log" do
    sign_in @other_user
    assert_no_difference "ActivityLogComment.count" do
      post activity_log_comments_url(activity_log_id: @activity_log.id),
           params: { activity_log_comment: { body: "x", category: "other" } }
    end
    assert_response :not_found
  end

  test "PATCH update changes body" do
    sign_in @user
    comment = @activity_log.comments.create!(body: "original", category: "other")

    patch activity_log_comment_url(@activity_log, comment),
          params: { activity_log_comment: { body: "edited", category: "obs" } }

    assert_redirected_to activity_path
    comment.reload
    assert_equal "edited", comment.body
    assert_equal "obs", comment.category
  end

  test "DELETE destroy removes the comment" do
    sign_in @user
    comment = @activity_log.comments.create!(body: "note", category: "other")

    assert_difference "ActivityLogComment.count", -1 do
      delete activity_log_comment_url(@activity_log, comment)
    end
    assert_redirected_to activity_path
  end
end
