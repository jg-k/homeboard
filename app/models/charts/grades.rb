# Grade pyramids: what the climber sent in a period, by grade, hardest at the
# top. One per home board, in that board's grading system order, and one per
# system board (Kilter, Tension). Each problem counts once however often it
# was repeated; on a home board it counts as a flash if any send was one.
#
# Outdoor ascents get three pyramids: bouldering, sport and trad. Their grades come
# in whatever system the crag uses, so ClimbingGrade puts them on Font or
# French first; onsights and flashes stack apart from other sends.
class Charts::Grades
  Pyramid = Data.define(:title, :series) do
    def rows = series.first[:data].size
  end

  SYSTEM_BOARDS = {
    "Kilter" => %w[kilter boardsesh_kilter],
    "Tension" => %w[boardsesh_tension]
  }.freeze
  SYSTEM_BOARD_ORDER = Boardsesh::Sync::KILTER_GRADE_MAP.values.uniq.freeze

  def initialize(user, period:)
    @user = user
    @from = period.starts_at
  end

  OUTDOOR = { boulder: "Outdoor bouldering", sport: "Outdoor sport", trad: "Outdoor trad" }.freeze
  OUTDOOR_FIRST_GO = %w[onsight flash].freeze

  def pyramids
    home_board_pyramids + system_board_pyramids + outdoor_pyramids
  end

  private

  def home_board_pyramids
    sends = BoardClimb.successful.for_user(@user)
                      .where(climbed_at: @from..)
                      .joins(problem: { board_layout: :board })
                      .pluck("boards.id", "problems.id", "problems.grade", :climb_type)

    sends.group_by(&:first).filter_map do |board_id, rows|
      board = @user.boards.find_by(id: board_id) or next
      by_problem = rows.group_by { _1[1] }.values
      flashes = by_problem.select { |climbs| climbs.any? { _1[3] == "flash" } }.map { _1.first[2] }
      others = by_problem.reject { |climbs| climbs.any? { _1[3] == "flash" } }.map { _1.first[2] }

      pyramid(board.name, board.grading_system&.grades || [], "Flash" => flashes, "Send" => others)
    end
  end

  def system_board_pyramids
    SYSTEM_BOARDS.filter_map do |name, boards|
      grades = SystemBoardClimb.joins(:activity_log)
                               .where(activity_logs: { user_id: @user.id })
                               .where(board: boards, is_send: true, climbed_at: @from..)
                               .distinct
                               .pluck(:climb_uuid, :angle, :displayed_grade)
                               .map(&:last)
      pyramid(name, SYSTEM_BOARD_ORDER, "Send" => grades) if grades.any?
    end
  end

  def outdoor_pyramids
    sends = CragAscent.logged_by(@user)
                      .where(ascent_date: @from.., ascent_type: CragAscent::RouteAttempts::SENDS)
                      .pluck(:thecrag_route_id, :ukc_route_id, :route_name, :crag_name, :grade, :gear_style, :ascent_type)

    by_discipline = sends.group_by { |*, grade, gear_style, _| ClimbingGrade.discipline(grade, gear_style: gear_style) }
    OUTDOOR.filter_map do |discipline, title|
      ascents = by_discipline[discipline] or next
      # The same route can come from theCrag and UKC, or be logged by hand.
      by_route = ascents.group_by { |crag_id, ukc_id, name, crag, *| crag_id || (ukc_id && "ukc-#{ukc_id}") || [ name, crag ] }.values
      first_go, other = by_route.partition { |route| route.any? { OUTDOOR_FIRST_GO.include?(_1.last) } }
      grade = ->(route) { [ ClimbingGrade.normalize(route.first[4], discipline: discipline), route.first[4] ] }

      pyramid(title, ClimbingGrade::SCALES.fetch(discipline),
              (discipline == :boulder ? "Flash" : "Onsight / flash") => first_go.map(&grade),
              "Send" => other.map(&grade))
    end
  end

  # grades_by_series maps a series name to one entry per problem sent: its
  # grade, or [grade, grade as logged] when the grade was converted. Rows run
  # from the hardest grade sent down to the easiest, with empty grades between
  # kept so the shape reads true; grades outside the known order (or none,
  # shown as "?") go below.
  #
  # Converted grades carry what was logged, so the tooltip on a "5c" bar can
  # say it was an E1 5b. That rides on the Chart.js dataset as loggedAs.
  def pyramid(title, order, grades_by_series)
    entries = grades_by_series.transform_values { |list| list.map { |grade, logged| [ grade.presence || "?", logged ] } }
    sent = entries.values.flatten(1).map(&:first)
    known = sent.select { order.include?(_1) }.uniq.sort_by { order.index(_1) }
    rows = known.any? ? order[order.index(known.first)..order.index(known.last)] : []
    rows = rows.reverse + (sent.uniq - rows).sort

    series = entries.map do |name, list|
      tally = list.map(&:first).tally
      line = { name: name, data: rows.map { [ _1, tally.fetch(_1, 0) ] } }
      logged_as = logged_as(list)
      logged_as.any? ? line.merge(dataset: { loggedAs: logged_as }) : line
    end
    Pyramid.new(title: title, series: series)
  end

  # { "5c" => ["E1 5b ×2", "E1 6a"] }, leaving out grades logged as they show.
  def logged_as(list)
    list.select { |grade, logged| logged.present? && logged != grade }
        .group_by(&:first)
        .transform_values { |pairs| pairs.map(&:last).tally.map { |logged, n| n > 1 ? "#{logged} ×#{n}" : logged } }
  end
end
