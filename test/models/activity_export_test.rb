require "test_helper"
require "zip"

class ActivityExportTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @service = ActivityExport.new(user: @user)
  end

  # --- JSON export ---

  test "to_json returns empty array when no activities" do
    ActivityLog.where(user: @user).destroy_all

    data = JSON.parse(@service.to_json)
    assert_equal [], data
  end

  test "to_json exports crag ascent with only relevant fields" do
    ActivityLog.where(user: @user).destroy_all

    ascent = CragAscent.create!(
      route_name: "The Nose", grade: "7a", ascent_type: "redpoint",
      gear_style: "sport", crag_name: "El Capitan", country: "Spain",
      comment: "Great climb", ascent_date: Time.current
    )
    ascent.create_activity_log!(user: @user, performed_at: ascent.ascent_date)

    data = JSON.parse(@service.to_json)
    assert_equal 1, data.size

    entry = data.first
    assert_equal "crag_ascent", entry["type"]
    assert_equal "The Nose", entry["route_name"]
    assert_equal "7a", entry["grade"]
    assert_equal "redpoint", entry["ascent_type"]
    assert_equal "sport", entry["gear_style"]
    assert_equal "El Capitan", entry["crag"]
    assert_equal "Spain", entry["country"]
    assert_equal "Great climb", entry["notes"]
    assert_nil entry["boulders"]
    assert_nil entry["value"]
  end

  test "to_json exports board climb with problem details" do
    ActivityLog.where(user: @user).destroy_all

    climb = board_climbs(:one)
    climb.create_activity_log!(user: @user, performed_at: climb.climbed_at)

    data = JSON.parse(@service.to_json)
    entry = data.find { |e| e["type"] == "board_climb" }

    assert_not_nil entry
    assert_equal climb.problem.name, entry["name"]
    assert_equal climb.problem.grade, entry["grade"]
    assert_equal climb.climb_type, entry["climb_type"]
  end

  test "to_json exports exercise with type details" do
    ActivityLog.where(user: @user).destroy_all

    exercise_type = exercise_types(:running)
    Exercise.create!(exercise_type: exercise_type, value: 30, notes: "Morning run", performed_at: Time.current)

    data = JSON.parse(@service.to_json)
    entry = data.find { |e| e["type"] == "exercise" }

    assert_not_nil entry
    assert_equal "Running", entry["name"]
    assert_equal "30.0", entry["value"].to_s
    assert_equal "minutes", entry["unit"]
  end

  test "to_json exports gym session" do
    ActivityLog.where(user: @user).destroy_all

    session = GymSession.create!(number_of_boulders: 15, duration_minutes: 90, notes: "Good session")
    session.create_activity_log!(user: @user, performed_at: Time.current)

    data = JSON.parse(@service.to_json)
    entry = data.find { |e| e["type"] == "gym_session" }

    assert_not_nil entry
    assert_equal 15, entry["boulders"]
    assert_equal 90, entry["duration_minutes"]
    assert_equal "Good session", entry["notes"]
  end

  test "to_json only exports activities for the given user" do
    other_user = users(:two)
    data = JSON.parse(ActivityExport.new(user: other_user).to_json)
    assert_equal [], data
  end

  test "to_json orders by date ascending" do
    ActivityLog.where(user: @user).destroy_all

    early = CragAscent.create!(route_name: "Early", grade: "6a", ascent_date: 2.days.ago)
    early.create_activity_log!(user: @user, performed_at: 2.days.ago)

    late = CragAscent.create!(route_name: "Late", grade: "6b", ascent_date: 1.day.ago)
    late.create_activity_log!(user: @user, performed_at: 1.day.ago)

    data = JSON.parse(@service.to_json)
    assert_equal "Early", data[0]["route_name"]
    assert_equal "Late", data[1]["route_name"]
  end

  # --- CSV ZIP export ---

  test "to_csv_zip returns valid zip with per-type CSVs" do
    ActivityLog.where(user: @user).destroy_all

    ascent = CragAscent.create!(route_name: "Test Route", grade: "6a", ascent_date: Time.current)
    ascent.create_activity_log!(user: @user, performed_at: ascent.ascent_date)

    session = GymSession.create!(number_of_boulders: 10, duration_minutes: 60)
    session.create_activity_log!(user: @user, performed_at: Time.current)

    zip_data = @service.to_csv_zip
    entries = extract_zip_entries(zip_data)

    assert_includes entries.keys, "crag_ascents.csv"
    assert_includes entries.keys, "gym_sessions.csv"
    assert_not_includes entries.keys, "board_climbs.csv"
    assert_not_includes entries.keys, "exercises.csv"

    crag_rows = CSV.parse(entries["crag_ascents.csv"], headers: true)
    assert_equal 1, crag_rows.size
    assert_equal "Test Route", crag_rows[0]["route_name"]
    assert_equal %w[date route_name grade ascent_type gear_style crag country partners source notes], crag_rows.headers

    gym_rows = CSV.parse(entries["gym_sessions.csv"], headers: true)
    assert_equal 1, gym_rows.size
    assert_equal "10", gym_rows[0]["boulders"]
    assert_equal %w[date boulders circuits duration_minutes notes], gym_rows.headers
  end

  test "to_csv_zip returns empty zip when no activities" do
    ActivityLog.where(user: @user).destroy_all

    zip_data = @service.to_csv_zip
    entries = extract_zip_entries(zip_data)
    assert_empty entries
  end

  private

  def extract_zip_entries(zip_data)
    entries = {}
    io = StringIO.new(zip_data)
    Zip::InputStream.open(io) do |zip|
      while (entry = zip.get_next_entry)
        entries[entry.name] = entry.get_input_stream.read
      end
    end
    entries
  end
end
