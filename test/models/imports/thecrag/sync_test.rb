require "test_helper"

class Imports::Thecrag::SyncTest < ActiveSupport::TestCase
  setup do
    @user = users(:two)
    @user.update!(thecrag_username: "jegk", thecrag_api_key: nil, thecrag_since_epoch: nil)
  end

  class FakeReader
    def initialize(rows) = @rows = rows
    def call = @rows
  end

  class TruncatedReader < FakeReader
    def truncated? = true
  end

  def row(overrides = {})
    Imports::Thecrag::Row.new({
      thecrag_ascent_id: "9001",
      ascent_date: Time.zone.parse("2026-06-01"),
      route_name: "Magic Flute",
      grade: "7a",
      ascent_type: "redpoint",
      gear_style: "sport",
      crag_name: "Siurana",
      country: "Spain",
      comment: "Fought for it.",
      epoch: 1_771_193_431
    }.merge(overrides))
  end

  def sync(rows, **options)
    Imports::Thecrag::Sync.new(user: @user, reader: FakeReader.new(rows), **options).call
  end

  test "imports a row into an ascent and an activity log" do
    assert_difference [ "CragAscent.count", "ActivityLog.count" ], 1 do
      result = sync([ row ])
      assert_equal 1, result.imported_count
    end

    ascent = CragAscent.find_by(thecrag_ascent_id: "9001")
    assert_equal "Magic Flute", ascent.route_name
    assert_equal "redpoint", ascent.ascent_type
    assert_equal "Fought for it.", ascent.comment
  end

  test "skips ascents already imported" do
    sync([ row ])

    assert_no_difference "CragAscent.count" do
      result = sync([ row ])
      assert_equal 1, result.skipped_count
    end
  end

  # The watermark is what makes the next API call cheap, so it has to move even
  # when every ascent we read turned out to be one we already had.
  test "remembers the highest epoch it read" do
    @user.update!(thecrag_api_key: "secret-key")

    sync([ row(epoch: 100), row(thecrag_ascent_id: "9002", epoch: 300) ])

    assert_equal 300, @user.reload.thecrag_since_epoch
  end

  test "the watermark survives a sync that found only duplicates" do
    @user.update!(thecrag_api_key: "secret-key")
    sync([ row(epoch: 300) ])

    sync([ row(epoch: 300) ])

    assert_equal 300, @user.reload.thecrag_since_epoch
  end

  # Past the watermark an ascent is out of reach: no later `since` asks for it
  # again, so one we failed to store must not push the watermark over itself.
  test "the watermark stops short of an ascent that would not save" do
    @user.update!(thecrag_api_key: "secret-key")

    result = sync([ row(epoch: 100), row(thecrag_ascent_id: "9002", route_name: nil, epoch: 300) ])

    assert_equal 1, result.errors.size
    assert_equal 100, @user.reload.thecrag_since_epoch
  end

  test "a read that stopped at the page cap leaves the watermark alone" do
    @user.update!(thecrag_api_key: "secret-key", thecrag_since_epoch: 50)

    Imports::Thecrag::Sync.new(user: @user, reader: TruncatedReader.new([ row(epoch: 300) ])).call

    assert_equal 50, @user.reload.thecrag_since_epoch
    assert_match(/too large/, @user.thecrag_sync_error)
  end

  test "a sync that worked clears the last failure" do
    @user.update!(thecrag_api_key: "secret-key", thecrag_sync_error: "theCrag rejected the API key")

    sync([ row ])

    assert_nil @user.reload.thecrag_sync_error
  end

  test "never moves the watermark backwards" do
    @user.update!(thecrag_api_key: "secret-key", thecrag_since_epoch: 500)

    sync([ row(epoch: 100) ])

    assert_equal 500, @user.reload.thecrag_since_epoch
  end

  test "hands the stored epoch to the API reader" do
    @user.update!(thecrag_api_key: "secret-key", thecrag_since_epoch: 4242)

    reader = Imports::Thecrag::Sync.new(user: @user).send(:build_reader)

    assert_instance_of Imports::Thecrag::Api, reader
    assert_equal 4242, reader.instance_variable_get(:@since)
  end

  test "a full sync ignores the stored epoch" do
    @user.update!(thecrag_api_key: "secret-key", thecrag_since_epoch: 4242)

    reader = Imports::Thecrag::Sync.new(user: @user, full: true).send(:build_reader)

    assert_nil reader.instance_variable_get(:@since)
  end

  test "falls back to the scraper when the climber has no key" do
    reader = Imports::Thecrag::Sync.new(user: @user, cookie: "abc123").send(:build_reader)

    assert_instance_of Imports::Thecrag::Scraper, reader
  end

  test "records where the ascent came from" do
    @user.update!(thecrag_api_key: "secret-key")
    sync([ row ])

    assert_equal "thecrag_api", CragAscent.find_by(thecrag_ascent_id: "9001").source
  end

  test "the scraper path still needs a cookie" do
    assert_raises(ArgumentError) do
      Imports::Thecrag::Sync.new(user: @user, cookie: nil).call
    end
  end

  test "the scraper path still needs a username" do
    @user.update!(thecrag_username: nil)

    assert_raises(ArgumentError) do
      Imports::Thecrag::Sync.new(user: @user, cookie: "abc123").call
    end
  end
end
