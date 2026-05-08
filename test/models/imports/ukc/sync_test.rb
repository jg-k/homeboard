require "test_helper"

class Imports::Ukc::SyncTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "imports rows and updates user sync timestamp" do
    rows = [
      Imports::Ukc::Scraper::Row.new(
        ukc_route_id: "43768", ascent_date: Time.zone.local(2026, 5, 6),
        route_name: "White Wine", grade: "f5", quality: nil,
        ascent_type: "Sent O/S", partners: nil,
        crag_name: "Kyloe-in-the-woods", crag_path: "/logbook/crags/kyloe-838/",
        route_path: "/logbook/crags/kyloe-838/white_wine-43768"
      ),
      Imports::Ukc::Scraper::Row.new(
        ukc_route_id: "324", ascent_date: Time.zone.local(2026, 1, 28),
        route_name: "Magic Flute", grade: "E1 5b", quality: 2,
        ascent_type: "Lead O/S", partners: "Sam",
        crag_name: "Back Bowden Doors", crag_path: "/logbook/crags/back_bowden-822/",
        route_path: "/logbook/crags/back_bowden-822/magic_flute-324"
      )
    ]
    scraper = Struct.new(:rows) { def call = rows }.new(rows)

    result = nil
    assert_difference [ "CragAscent.count", "ActivityLog.count" ], 2 do
      result = Imports::Ukc::Sync.new(user: @user, ukc_user_id: "363619", scraper: scraper).call
    end

    assert_equal 2, result.imported_count
    assert_equal 0, result.skipped_count
    assert_empty result.errors

    @user.reload
    assert_equal "363619", @user.ukc_user_id
    assert_not_nil @user.ukc_synced_at

    ascent = CragAscent.find_by(ukc_route_id: "43768")
    assert_equal "White Wine", ascent.route_name
    assert_equal "f5", ascent.grade
    assert_equal "onsight", ascent.ascent_type
    assert_equal "ukc_scrape", ascent.source

    trad = CragAscent.find_by(ukc_route_id: "324")
    assert_equal 2, trad.quality
    assert_equal "onsight", trad.ascent_type
    assert_equal "Sam", trad.partners
  end

  test "skips duplicates on a second sync" do
    rows = [
      Imports::Ukc::Scraper::Row.new(
        ukc_route_id: "43768", ascent_date: Time.zone.local(2026, 5, 6),
        route_name: "White Wine", grade: "f5", quality: nil,
        ascent_type: "Sent O/S", partners: nil,
        crag_name: "Kyloe", crag_path: "/c/",
        route_path: "/r/"
      )
    ]
    scraper = Struct.new(:rows) { def call = rows }.new(rows)

    Imports::Ukc::Sync.new(user: @user, ukc_user_id: "363619", scraper: scraper).call

    result = nil
    assert_no_difference "CragAscent.count" do
      result = Imports::Ukc::Sync.new(user: @user, ukc_user_id: "363619", scraper: scraper).call
    end

    assert_equal 0, result.imported_count
    assert_equal 1, result.skipped_count
  end

  test "raises when ukc_user_id is missing" do
    assert_raises(ArgumentError) do
      Imports::Ukc::Sync.new(user: @user, ukc_user_id: nil, scraper: stub_scraper([])).call
    end
  end

  test "records error when row has no date" do
    rows = [
      Imports::Ukc::Scraper::Row.new(
        ukc_route_id: "999", ascent_date: nil,
        route_name: "Mystery Route", grade: "6a", quality: nil,
        ascent_type: "Lead O/S", partners: nil,
        crag_name: "Crag", crag_path: nil, route_path: nil
      )
    ]
    result = Imports::Ukc::Sync.new(user: @user, ukc_user_id: "363619", scraper: stub_scraper(rows)).call
    assert_equal 0, result.imported_count
    assert_equal 1, result.errors.size
  end

  private

  def stub_scraper(rows)
    Struct.new(:rows) { def call = rows }.new(rows)
  end
end
