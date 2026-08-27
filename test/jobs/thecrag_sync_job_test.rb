require "test_helper"

class ThecragSyncJobTest < ActiveJob::TestCase
  # Stands in for the API reader so the job can be exercised without a network
  # call; what we care about is that the job reached for it at all.
  class FakeApi
    # The job rescues these off the constant it reaches for, which is the one
    # being stubbed, so the stand-in has to answer to the same names.
    InvalidKey = Imports::Thecrag::Api::InvalidKey
    BudgetExhausted = Imports::Thecrag::Api::BudgetExhausted

    singleton_class.attr_accessor :last_key, :raising

    def self.new(key, **)
      self.last_key = key
      allocate
    end

    def call
      raise self.class.raising, "nope" if self.class.raising

      []
    end
  end

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

  # With a personal key the climber reads their own logbook, so a missing admin
  # cookie is no longer a reason to skip them.
  test "syncs through the API when the climber has a key" do
    @user.update!(thecrag_api_key: "secret-key")
    assert_nil Imports::Thecrag.session_cookie

    stub_const(Imports::Thecrag, :Api, FakeApi) do
      ThecragSyncJob.perform_now(@user.id)
    end

    assert_equal "secret-key", FakeApi.last_key
    assert @user.reload.thecrag_synced_at.present?
  end

  # Neither a revoked key nor a spent weekly budget is worth retrying, so the
  # job says so in the log rather than failing.
  test "a rejected key stops the job quietly" do
    @user.update!(thecrag_api_key: "secret-key")
    FakeApi.raising = Imports::Thecrag::Api::InvalidKey

    stub_const(Imports::Thecrag, :Api, FakeApi) do
      assert_nothing_raised { ThecragSyncJob.perform_now(@user.id) }
    end

    assert_nil @user.reload.thecrag_synced_at
  ensure
    FakeApi.raising = nil
  end

  # Quietly is not silently: settings would otherwise go on showing the last
  # successful sync, and the climber would never learn their key had stopped.
  test "a rejected key is remembered where the climber can see it" do
    @user.update!(thecrag_api_key: "secret-key")
    FakeApi.raising = Imports::Thecrag::Api::InvalidKey

    stub_const(Imports::Thecrag, :Api, FakeApi) do
      ThecragSyncJob.perform_now(@user.id)
    end

    assert_equal "nope", @user.reload.thecrag_sync_error
  ensure
    FakeApi.raising = nil
  end

  test "a key holder needs no username" do
    @user.update!(thecrag_username: nil, thecrag_api_key: "secret-key")

    stub_const(Imports::Thecrag, :Api, FakeApi) do
      ThecragSyncJob.perform_now(@user.id)
    end

    assert_equal "secret-key", FakeApi.last_key
    assert @user.reload.thecrag_synced_at.present?
  end

  test "falls back to the admin's stored cookie" do
    admin = users(:one)
    admin.update!(role: "admin", thecrag_session_cookie: "abc123")

    assert_equal "abc123", Imports::Thecrag.session_cookie
  end
end
