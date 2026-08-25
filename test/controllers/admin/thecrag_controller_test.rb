require "test_helper"

class Admin::ThecragControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one)
    @admin.update!(role: "admin")
    @climber = users(:two)
    @climber.update!(thecrag_username: "kmerwe")
  end

  test "non-admins are turned away" do
    sign_in @climber
    get admin_thecrag_url

    assert_redirected_to root_path
  end

  test "shows the climbers who have a theCrag username" do
    sign_in @admin
    get admin_thecrag_url

    assert_response :success
    assert_match "kmerwe", response.body
  end

  test "saves the session cookie on the admin" do
    sign_in @admin
    patch admin_thecrag_url, params: { thecrag_session_cookie: "  abc123  " }

    assert_redirected_to admin_thecrag_path
    assert_equal "abc123", @admin.reload.thecrag_session_cookie
  end

  test "blanking the field clears the stored cookie" do
    @admin.update!(thecrag_session_cookie: "abc123")
    sign_in @admin
    patch admin_thecrag_url, params: { thecrag_session_cookie: "" }

    assert_nil @admin.reload.thecrag_session_cookie
  end

  test "syncing without a cookie says so instead of running" do
    sign_in @admin
    assert_no_enqueued_jobs only: ThecragSyncJob do
      post sync_admin_thecrag_url
    end

    assert_equal "Paste a session cookie first.", flash[:alert]
  end

  test "sync enqueues a job per climber, carrying the admin's cookie" do
    @admin.update!(thecrag_session_cookie: "abc123")
    sign_in @admin

    assert_enqueued_with(job: ThecragSyncJob, args: [ @climber.id, "kmerwe", "abc123" ]) do
      post sync_admin_thecrag_url
    end
  end

  test "sync can target a single climber" do
    @admin.update!(thecrag_session_cookie: "abc123", thecrag_username: "jegk")
    sign_in @admin

    assert_enqueued_jobs 1, only: ThecragSyncJob do
      post sync_admin_thecrag_url(user_id: @climber.id)
    end
  end
end
