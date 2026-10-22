require "test_helper"

class Charts::GradesTest < ActiveSupport::TestCase
  setup do
    travel_to Time.zone.local(2026, 10, 21, 12)
    @user = users(:one)
    @board = boards(:one)
    @board.update!(name: "Garage board",
                   grading_system: GradingSystem.create!(name: "V scale", grades: %w[V3 V4 V5 V6 V7 V8]))
    @layout = board_layouts(:one)
  end

  def problem(grade) = @layout.problems.create!(name: "#{grade} problem", grade: grade, start_holds: [ { x: 0.1, y: 0.1 } ])

  def climb(problem, type, at: 3.days.ago)
    problem.board_climbs.create!(climb_type: type, climbed_at: at)
           .tap { _1.create_activity_log!(user: @user, performed_at: at) }
  end

  def kilter(grade, uuid:, angle: 40, send: true, board: "boardsesh_kilter")
    SystemBoardClimb.create!(uuid: SecureRandom.uuid, climb_uuid: uuid, board: board, climb_name: uuid,
                             angle: angle, displayed_grade: grade, is_send: send, climbed_at: 2.days.ago)
                    .tap { _1.create_activity_log!(user: @user, performed_at: 2.days.ago) }
  end

  def pyramids(key = "3m") = Charts::Grades.new(@user, period: Charts::Period.find(key)).pyramids.index_by(&:title)

  def rows(pyramid, series) = pyramid.series.find { _1[:name] == series }[:data]

  test "stacks a home board's sends hardest first, in its grading system order, gaps included" do
    climb(problem("V4"), :sent)
    climb(problem("V7"), :flash)

    pyramid = pyramids.fetch("Garage board")

    assert_equal [ [ "V7", 0 ], [ "V6", 0 ], [ "V5", 0 ], [ "V4", 1 ] ], rows(pyramid, "Send")
    assert_equal [ [ "V7", 1 ], [ "V6", 0 ], [ "V5", 0 ], [ "V4", 0 ] ], rows(pyramid, "Flash")
  end

  test "counts a problem once, as a flash if any send was one" do
    repeated = problem("V5")
    climb(repeated, :flash, at: 10.days.ago)
    climb(repeated, :sent, at: 2.days.ago)
    climb(repeated, :sent, at: 1.day.ago)

    pyramid = pyramids.fetch("Garage board")

    assert_equal [ [ "V5", 1 ] ], rows(pyramid, "Flash")
    assert_equal [ [ "V5", 0 ] ], rows(pyramid, "Send")
  end

  test "attempts and sends outside the period are left out" do
    climb(problem("V4"), :attempt)
    climb(problem("V6"), :sent, at: 2.months.ago)

    assert_not pyramids("4w").key?("Garage board")
    assert pyramids("3m").key?("Garage board")
  end

  # Problems are validated against the grading system, but the system can be
  # edited afterwards, leaving older problems on a grade it no longer lists.
  test "grades the board's system no longer lists go below the known ones" do
    climb(problem("V4"), :sent)
    climb(problem("V5").tap { _1.update_column(:grade, "Project") }, :sent)

    assert_equal [ "V4", "Project" ], rows(pyramids.fetch("Garage board"), "Send").map(&:first)
  end

  test "a system board counts each climb at each angle once, in Kilter grade order" do
    kilter("6b/V4", uuid: "a")
    kilter("6b/V4", uuid: "a")
    kilter("6b/V4", uuid: "a", angle: 45)
    kilter("6c/V5", uuid: "b")
    kilter("7a/V6", uuid: "c", send: false)

    pyramid = pyramids.fetch("Kilter")

    assert_equal [ "Send" ], pyramid.series.map { _1[:name] }
    assert_equal [ [ "6c/V5", 1 ], [ "6b+/V4", 0 ], [ "6b/V4", 2 ] ], rows(pyramid, "Send")
  end

  test "Tension gets its own pyramid" do
    kilter("6a/V3", uuid: "t", board: "boardsesh_tension")

    assert_equal [ "Tension" ], pyramids.keys
  end

  def ascent(name, grade, type, gear_style: nil, route_id: nil, on: 5.days.ago)
    CragAscent.create!(route_name: name, crag_name: "Kyloe", grade: grade, ascent_type: type,
                       gear_style: gear_style, thecrag_route_id: route_id, ascent_date: on)
              .tap { _1.create_activity_log!(user: @user, performed_at: on) }
  end

  test "outdoor bouldering, sport and trad get a pyramid each, on Font and French" do
    ascent("White Wine", "f5", "flash", gear_style: "boulder")
    ascent("Crystal", "V3", "send", gear_style: "boulder")
    ascent("Magic Flute", "E1 5b", "onsight", gear_style: "trad")
    ascent("Old Lawbreaker", "6b", "redpoint", gear_style: "sport")

    boulders = pyramids.fetch("Outdoor bouldering")
    sport = pyramids.fetch("Outdoor sport")
    trad = pyramids.fetch("Outdoor trad")

    assert_equal [ [ "6A", 1 ], [ "5C", 0 ], [ "5B", 0 ], [ "5A", 0 ] ], rows(boulders, "Send")
    assert_equal [ [ "6A", 0 ], [ "5C", 0 ], [ "5B", 0 ], [ "5A", 1 ] ], rows(boulders, "Flash")
    assert_equal [ [ "6b", 1 ] ], rows(sport, "Send")
    assert_equal [ [ "6b", 0 ] ], rows(sport, "Onsight / flash")
    assert_equal [ [ "5c", 1 ] ], rows(trad, "Onsight / flash")
    assert_equal [ [ "5c", 0 ] ], rows(trad, "Send")
  end

  test "without a gear style, a British grade goes to trad and a French one to sport" do
    ascent("Unsorted trad", "HVS 5a", "redpoint")
    ascent("Unsorted sport", "7a", "redpoint")

    assert_equal [ [ "5b", 1 ] ], rows(pyramids.fetch("Outdoor trad"), "Send")
    assert_equal [ [ "7a", 1 ] ], rows(pyramids.fetch("Outdoor sport"), "Send")
  end

  test "an outdoor route counts once, at its best style, and attempts do not count" do
    ascent("Darkness Falling", "6a+", "attempt", route_id: "407", on: 20.days.ago)
    ascent("Darkness Falling", "6a+", "redpoint", route_id: "407", on: 10.days.ago)
    ascent("Darkness Falling", "6a+", "redpoint", route_id: "407", on: 2.days.ago)
    ascent("Unfinished", "7a", "hang_dog")

    assert_equal [ [ "6a+", 1 ] ], rows(pyramids.fetch("Outdoor sport"), "Send")
  end

  test "a grade no system reads still counts, below the rest" do
    ascent("Mystery", "Project", "send", gear_style: "sport")
    ascent("Known", "6a", "send", gear_style: "sport")

    assert_equal [ [ "6a", 1 ], [ "?", 1 ] ], rows(pyramids.fetch("Outdoor sport"), "Send")
  end

  test "converted grades carry what was logged, for the tooltip" do
    ascent("Magic Flute", "E1 5b", "redpoint", gear_style: "trad")
    ascent("Bitter End", "E1 5b", "redpoint", gear_style: "trad")
    ascent("Overhang", "E1 6a", "redpoint", gear_style: "trad")
    ascent("Old Lawbreaker", "6b", "redpoint", gear_style: "sport")

    trad = pyramids.fetch("Outdoor trad").series.find { _1[:name] == "Send" }
    sport = pyramids.fetch("Outdoor sport").series.find { _1[:name] == "Send" }

    assert_equal({ "5c" => [ "E1 5b ×2", "E1 6a" ] }, trad.dig(:dataset, :loggedAs))
    assert_nil sport[:dataset], "grades logged as they show need no note"
  end

  test "home board pyramids need no logged grades" do
    climb(problem("V4"), :sent)

    assert pyramids.fetch("Garage board").series.none? { _1.key?(:dataset) }
  end
end
