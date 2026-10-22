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
end
