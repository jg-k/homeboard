require "test_helper"

class ThecragSyncAllJobTest < ActiveJob::TestCase
  test "enqueues a sync for climbers we can reach" do
    User.update_all(thecrag_username: nil, thecrag_api_key: nil)
    named = users(:one)
    named.update!(thecrag_username: "jegk")
    keyed = users(:two)
    keyed.update!(thecrag_api_key: "secret-key")

    assert_enqueued_jobs 2, only: ThecragSyncJob do
      ThecragSyncAllJob.perform_now
    end
  end
end
