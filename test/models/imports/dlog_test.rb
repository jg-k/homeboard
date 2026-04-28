require "test_helper"

class Imports::DlogTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "imports a single row" do
    csv = csv_content([
      { "Name" => "Magic Flute", "Grade" => "E1 5b", "Style" => "Lead O/S",
        "Date" => "28/Jan/26", "Crag" => "Back Bowden Doors", "Country" => "England",
        "Type" => "Trad", "Notes" => "Great route" }
    ])

    result = nil
    assert_difference [ "CragAscent.count", "ActivityLog.count" ], 1 do
      result = Imports::Dlog.new(user: @user, csv_content: csv).call
    end

    assert_equal 1, result.imported_count
    assert_equal 0, result.skipped_count
    assert_empty result.errors

    ascent = CragAscent.last
    assert_equal "Magic Flute", ascent.route_name
    assert_equal "E1 5b", ascent.grade
    assert_equal "onsight", ascent.ascent_type
    assert_equal "trad", ascent.gear_style
    assert_equal "Back Bowden Doors", ascent.crag_name
    assert_equal "England", ascent.country
    assert_equal "Great route", ascent.comment
    assert_equal Date.new(2026, 1, 28), ascent.ascent_date.to_date
    assert_equal "ukc_dlog", ascent.source
  end

  test "imports multiple rows" do
    csv = csv_content([
      { "Name" => "Route A", "Grade" => "6a", "Style" => "Lead", "Date" => "15/Mar/25",
        "Crag" => "Crag X", "Country" => "Spain", "Type" => "Sport" },
      { "Name" => "Route B", "Grade" => "V3", "Style" => "Sent", "Date" => "16/Mar/25",
        "Crag" => "Crag Y", "Country" => "Spain", "Type" => "Boulder" }
    ])

    result = nil
    assert_difference [ "CragAscent.count", "ActivityLog.count" ], 2 do
      result = Imports::Dlog.new(user: @user, csv_content: csv).call
    end

    assert_equal 2, result.imported_count
    assert_equal 0, result.skipped_count
  end

  test "skips duplicates based on route name, date, and crag" do
    csv = csv_content([
      { "Name" => "Magic Flute", "Grade" => "E1 5b", "Style" => "Lead O/S",
        "Date" => "28/Jan/26", "Crag" => "Back Bowden Doors", "Type" => "Trad" }
    ])

    Imports::Dlog.new(user: @user, csv_content: csv).call

    result = nil
    assert_no_difference "CragAscent.count" do
      result = Imports::Dlog.new(user: @user, csv_content: csv).call
    end

    assert_equal 0, result.imported_count
    assert_equal 1, result.skipped_count
  end

  test "does not skip same route for different user" do
    csv = csv_content([
      { "Name" => "Magic Flute", "Grade" => "E1 5b", "Style" => "Lead O/S",
        "Date" => "28/Jan/26", "Crag" => "Back Bowden Doors", "Type" => "Trad" }
    ])

    Imports::Dlog.new(user: @user, csv_content: csv).call

    other_user = users(:two)
    result = nil
    assert_difference "CragAscent.count", 1 do
      result = Imports::Dlog.new(user: other_user, csv_content: csv).call
    end

    assert_equal 1, result.imported_count
  end

  test "handles missing date" do
    csv = csv_content([
      { "Name" => "Route A", "Grade" => "6a", "Style" => "Lead", "Date" => "",
        "Crag" => "Crag X", "Type" => "Sport" }
    ])

    result = nil
    assert_no_difference "CragAscent.count" do
      result = Imports::Dlog.new(user: @user, csv_content: csv).call
    end

    assert_equal 0, result.imported_count
    assert_equal 1, result.errors.size
    assert_match(/missing or invalid date/, result.errors.first)
  end

  test "maps styles correctly" do
    styles = {
      "Lead O/S" => "onsight",
      "Lead Flash" => "flash",
      "Lead RP" => "redpoint",
      "Lead" => "redpoint",
      "Lead dog" => "hang_dog",
      "Lead G/U" => "send",
      "AltLd" => "redpoint",
      "Solo" => "send",
      "Sent" => "send",
      "Flash" => "flash",
      "O/S" => "onsight",
      "Top Rope" => "tick",
      "2nd" => "tick",
      "Attempt" => "attempt",
      "Hang" => "hang_dog"
    }

    styles.each_with_index do |(dlog_style, expected), i|
      csv = csv_content([
        { "Name" => "Route #{i}", "Grade" => "6a", "Style" => dlog_style,
          "Date" => "01/Jun/25", "Crag" => "Crag #{i}", "Type" => "Sport" }
      ])

      Imports::Dlog.new(user: @user, csv_content: csv).call
      ascent = CragAscent.order(:created_at).last
      assert_equal expected, ascent.ascent_type, "Expected '#{dlog_style}' to map to '#{expected}'"
    end
  end

  test "maps gear styles correctly" do
    gear_styles = { "Sport" => "sport", "Trad" => "trad", "Boulder" => "boulder" }

    gear_styles.each_with_index do |(dlog_type, expected), i|
      csv = csv_content([
        { "Name" => "GS Route #{i}", "Grade" => "6a", "Style" => "Lead",
          "Date" => "02/Jun/25", "Crag" => "GS Crag #{i}", "Type" => dlog_type }
      ])

      Imports::Dlog.new(user: @user, csv_content: csv).call
      ascent = CragAscent.order(:created_at).last
      assert_equal expected, ascent.gear_style, "Expected '#{dlog_type}' to map to '#{expected}'"
    end
  end

  test "creates activity log with correct user and date" do
    csv = csv_content([
      { "Name" => "Test Route", "Grade" => "HVS 5a", "Style" => "Lead O/S",
        "Date" => "15/Jun/25", "Crag" => "Test Crag", "Type" => "Trad" }
    ])

    Imports::Dlog.new(user: @user, csv_content: csv).call
    ascent = CragAscent.last

    assert_equal ascent.ascent_date, ascent.activity_log.performed_at
    assert_equal @user, ascent.activity_log.user
  end

  test "strips UTF-8 BOM" do
    csv = "\xEF\xBB\xBF" + csv_content([
      { "Name" => "BOM Route", "Grade" => "6a", "Style" => "Lead",
        "Date" => "01/Jun/25", "Crag" => "BOM Crag", "Type" => "Sport" }
    ])

    result = nil
    assert_difference "CragAscent.count", 1 do
      result = Imports::Dlog.new(user: @user, csv_content: csv).call
    end

    assert_equal 1, result.imported_count
  end

  test "imports real DLOG fixture file" do
    csv = file_fixture("dlog-sample.csv").read

    result = nil
    assert_difference [ "CragAscent.count", "ActivityLog.count" ], 1 do
      result = Imports::Dlog.new(user: @user, csv_content: csv).call
    end

    assert_equal 1, result.imported_count
    assert_equal 0, result.skipped_count
    assert_empty result.errors

    ascent = CragAscent.last
    assert_equal "Magic Flute", ascent.route_name
    assert_equal "E1 5b", ascent.grade
    assert_equal "onsight", ascent.ascent_type
    assert_equal "trad", ascent.gear_style
    assert_equal "Back Bowden Doors", ascent.crag_name
    assert_equal "England", ascent.country

    # Re-import should skip
    result2 = Imports::Dlog.new(user: @user, csv_content: csv).call
    assert_equal 0, result2.imported_count
    assert_equal 1, result2.skipped_count
  end

  test "parses various date formats" do
    dates = {
      "28/Jan/26" => Date.new(2026, 1, 28),
      "01/Dec/24" => Date.new(2024, 12, 1),
      "15/Mar/25" => Date.new(2025, 3, 15),
      "??/Oct/25" => Date.new(2025, 10, 1),
      "??/Aug/22" => Date.new(2022, 8, 1),
      "???/2025" => Date.new(2025, 1, 1),
      "???/2022" => Date.new(2022, 1, 1)
    }

    dates.each_with_index do |(date_str, expected_date), i|
      csv = csv_content([
        { "Name" => "Date Route #{i}", "Grade" => "6a", "Style" => "Lead",
          "Date" => date_str, "Crag" => "Date Crag #{i}", "Type" => "Sport" }
      ])

      Imports::Dlog.new(user: @user, csv_content: csv).call
      ascent = CragAscent.order(:created_at).last
      assert_equal expected_date, ascent.ascent_date.to_date, "Expected '#{date_str}' to parse to #{expected_date}"
    end
  end

  private

  def csv_content(rows)
    headers = %w[Name Grade Style Partner(empty) Notes Date Crag County Region Country Pitches Type]

    CSV.generate do |csv|
      csv << headers
      rows.each do |row|
        csv << headers.map { |h| row[h] || "" }
      end
    end
  end
end
