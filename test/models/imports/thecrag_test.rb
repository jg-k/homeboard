require "test_helper"

class Imports::ThecragTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "imports multiple rows from CSV" do
    csv = csv_content([
      { "Ascent ID" => "100", "Route Name" => "Route Alpha", "Ascent Date" => "2025-06-01",
        "Ascent Type" => "Red point", "Ascent Gear Style" => "Sport", "Ascent Grade" => "7a",
        "Route Grade" => "6c", "Route Gear Style" => "Sport", "Route Height" => "25",
        "Crag Name" => "Crag A", "Crag Path" => "Europe > Spain", "Country" => "Spain",
        "With" => "Partner A", "Comment" => "Nice route", "Quality" => "***" },
      { "Ascent ID" => "101", "Route Name" => "Route Beta", "Ascent Date" => "2025-06-02",
        "Ascent Type" => "Onsight", "Ascent Gear Style" => "Trad", "Ascent Grade" => "5b",
        "Route Grade" => "5a", "Route Gear Style" => "Trad", "Route Height" => "30",
        "Crag Name" => "Crag B", "Crag Path" => "Europe > UK", "Country" => "UK",
        "With" => "", "Comment" => "", "Quality" => "**" }
    ])

    result = nil
    assert_difference [ "CragAscent.count", "ActivityLog.count" ], 2 do
      result = Imports::Thecrag.new(user: @user, csv_content: csv).call
    end

    assert_equal 2, result.imported_count
    assert_equal 0, result.skipped_count
    assert_empty result.errors

    ascent = CragAscent.find_by(thecrag_ascent_id: "100")
    assert_equal "Route Alpha", ascent.route_name
    assert_equal "redpoint", ascent.ascent_type
    assert_equal "sport", ascent.gear_style
    assert_equal "7a", ascent.grade
    assert_equal 25, ascent.route_height
    assert_equal "Crag A", ascent.crag_name
    assert_equal "Europe > Spain", ascent.crag_path
    assert_equal "Spain", ascent.country
    assert_equal "Partner A", ascent.partners
    assert_equal "Nice route", ascent.comment
    assert_equal 3, ascent.quality
    assert_equal "thecrag", ascent.source
  end

  test "skips duplicate ascent IDs" do
    csv = csv_content([
      { "Ascent ID" => "200", "Route Name" => "Route A", "Ascent Date" => "2025-06-01",
        "Ascent Type" => "Flash", "Ascent Gear Style" => "Sport" }
    ])

    Imports::Thecrag.new(user: @user, csv_content: csv).call

    result = nil
    assert_no_difference "CragAscent.count" do
      result = Imports::Thecrag.new(user: @user, csv_content: csv).call
    end

    assert_equal 0, result.imported_count
    assert_equal 1, result.skipped_count
  end

  test "handles missing date" do
    csv = csv_content([
      { "Ascent ID" => "300", "Route Name" => "Route A", "Ascent Date" => "",
        "Ascent Type" => "Flash", "Ascent Gear Style" => "Sport" }
    ])

    result = nil
    assert_no_difference "CragAscent.count" do
      result = Imports::Thecrag.new(user: @user, csv_content: csv).call
    end

    assert_equal 0, result.imported_count
    assert_equal 1, result.errors.size
    assert_match(/missing or invalid date/, result.errors.first)
  end

  test "maps ascent types correctly" do
    types = {
      "Onsight" => "onsight",
      "Flash" => "flash",
      "Red point" => "redpoint",
      "Send" => "send",
      "Tick" => "tick",
      "Attempt" => "attempt",
      "Hang dog" => "hang_dog",
      "Clean" => "clean",
      "Pink point" => "pink_point"
    }

    types.each_with_index do |(csv_type, expected), i|
      csv = csv_content([
        { "Ascent ID" => "400#{i}", "Route Name" => "Route #{i}", "Ascent Date" => "2025-06-01",
          "Ascent Type" => csv_type, "Ascent Gear Style" => "Sport" }
      ])

      Imports::Thecrag.new(user: @user, csv_content: csv).call
      ascent = CragAscent.find_by(thecrag_ascent_id: "400#{i}")
      assert_equal expected, ascent.ascent_type, "Expected #{csv_type} to map to #{expected}"
    end
  end

  test "maps gear styles correctly" do
    styles = { "Sport" => "sport", "Trad" => "trad", "Boulder" => "boulder" }

    styles.each_with_index do |(csv_style, expected), i|
      csv = csv_content([
        { "Ascent ID" => "500#{i}", "Route Name" => "Route #{i}", "Ascent Date" => "2025-06-01",
          "Ascent Type" => "Flash", "Ascent Gear Style" => csv_style }
      ])

      Imports::Thecrag.new(user: @user, csv_content: csv).call
      ascent = CragAscent.find_by(thecrag_ascent_id: "500#{i}")
      assert_equal expected, ascent.gear_style, "Expected #{csv_style} to map to #{expected}"
    end
  end

  test "falls back to route grade when ascent grade is missing" do
    csv = csv_content([
      { "Ascent ID" => "600", "Route Name" => "Route A", "Ascent Date" => "2025-06-01",
        "Ascent Type" => "Flash", "Ascent Gear Style" => "Sport",
        "Ascent Grade" => "", "Route Grade" => "6a+" }
    ])

    Imports::Thecrag.new(user: @user, csv_content: csv).call
    ascent = CragAscent.find_by(thecrag_ascent_id: "600")
    assert_equal "6a+", ascent.grade
  end

  test "falls back to route gear style when ascent gear style is missing" do
    csv = csv_content([
      { "Ascent ID" => "700", "Route Name" => "Route A", "Ascent Date" => "2025-06-01",
        "Ascent Type" => "Flash", "Ascent Gear Style" => "", "Route Gear Style" => "Trad" }
    ])

    Imports::Thecrag.new(user: @user, csv_content: csv).call
    ascent = CragAscent.find_by(thecrag_ascent_id: "700")
    assert_equal "trad", ascent.gear_style
  end

  test "creates activity log with correct performed_at" do
    csv = csv_content([
      { "Ascent ID" => "800", "Route Name" => "Route A", "Ascent Date" => "2025-06-15",
        "Ascent Type" => "Flash", "Ascent Gear Style" => "Sport" }
    ])

    Imports::Thecrag.new(user: @user, csv_content: csv).call
    ascent = CragAscent.find_by(thecrag_ascent_id: "800")
    assert_equal ascent.ascent_date, ascent.activity_log.performed_at
    assert_equal @user, ascent.activity_log.user
  end

  test "strips UTF-8 BOM from content" do
    csv = "\xEF\xBB\xBF" + csv_content([
      { "Ascent ID" => "900", "Route Name" => "Route BOM", "Ascent Date" => "2025-06-01",
        "Ascent Type" => "Flash", "Ascent Gear Style" => "Sport" }
    ])

    result = nil
    assert_difference "CragAscent.count", 1 do
      result = Imports::Thecrag.new(user: @user, csv_content: csv).call
    end

    assert_equal 1, result.imported_count
  end

  test "imports real theCrag CSV fixture file" do
    csv = file_fixture("thecrag-sample.csv").read

    result = nil
    assert_difference "CragAscent.count", 54 do
      assert_difference "ActivityLog.count", 54 do
        result = Imports::Thecrag.new(user: @user, csv_content: csv).call
      end
    end

    assert_equal 54, result.imported_count
    assert_equal 0, result.skipped_count
    assert_empty result.errors

    # Spot-check first row
    ascent = CragAscent.find_by(thecrag_ascent_id: "12301543707")
    assert_equal "Old Lawbreaker", ascent.route_name
    assert_equal "tick", ascent.ascent_type
    assert_equal "sport", ascent.gear_style
    assert_equal "6b", ascent.grade
    assert_equal 12, ascent.route_height
    assert_equal "Lowland Outcrops", ascent.crag_name
    assert_equal "United Kingdom", ascent.country
    assert_nil ascent.quality  # single star in "Route Stars" column, not "Quality"

    # Check a trad route
    tube = CragAscent.find_by(thecrag_ascent_id: "12126847773")
    assert_equal "Tube", tube.route_name
    assert_equal "redpoint", tube.ascent_type
    assert_equal "trad", tube.gear_style
    assert_equal "E4 5c", tube.grade

    # Check a boulder
    anapurna = CragAscent.find_by(thecrag_ascent_id: "11918588277")
    assert_equal "Anapurna", anapurna.route_name
    assert_equal "send", anapurna.ascent_type
    assert_equal "boulder", anapurna.gear_style
    assert_equal "5A+", anapurna.grade

    # Check activity log dates
    assert_equal tube.ascent_date, tube.activity_log.performed_at
    assert_equal @user, tube.activity_log.user

    # Re-import should skip all
    result2 = Imports::Thecrag.new(user: @user, csv_content: csv).call
    assert_equal 0, result2.imported_count
    assert_equal 54, result2.skipped_count
  end

  private

  def csv_content(rows)
    headers = [ "Ascent ID", "Route Name", "Ascent Date", "Ascent Type",
                "Ascent Gear Style", "Route Gear Style", "Ascent Grade",
                "Route Grade", "Route Height", "Crag Name", "Crag Path",
                "Country", "With", "Comment", "Quality" ]

    CSV.generate do |csv|
      csv << headers
      rows.each do |row|
        csv << headers.map { |h| row[h] || "" }
      end
    end
  end
end
