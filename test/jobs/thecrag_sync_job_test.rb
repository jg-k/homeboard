require "test_helper"

class ThecragSyncJobTest < ActiveJob::TestCase
  setup do
    @user = users(:two)
    @user.update!(thecrag_username: "kmerwe")
  end

  test "does nothing without a theCrag username" do
    @user.update!(thecrag_username: nil)

    assert_nothing_raised { ThecragSyncJob.perform_now(@user.id) }
  end

  # The settings-page button enqueues without a cookie; if no admin has saved
  # one, that should be a log line rather than a failed job.
  test "skips quietly when no admin session cookie is saved" do
    assert_no_difference "CragAscent.count" do
      assert_nothing_raised { ThecragSyncJob.perform_now(@user.id) }
    end
  end

  test "falls back to the admin's stored cookie" do
    admin = users(:one)
    admin.update!(role: "admin", thecrag_session_cookie: "abc123")

    assert_equal "abc123", Imports::Thecrag.session_cookie
  end
end
