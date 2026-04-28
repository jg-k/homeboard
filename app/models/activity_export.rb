require "zip"

class ActivityExport
  CSV_SCHEMAS = {
    "BoardClimb" => {
      filename: "board_climbs.csv",
      headers: %w[date name grade climb_type moves notes]
    },
    "Exercise" => {
      filename: "exercises.csv",
      headers: %w[date name value unit notes]
    },
    "GymSession" => {
      filename: "gym_sessions.csv",
      headers: %w[date boulders circuits duration_minutes notes]
    },
    "CragAscent" => {
      filename: "crag_ascents.csv",
      headers: %w[date route_name grade ascent_type gear_style crag country partners source notes]
    },
    "SystemBoardClimb" => {
      filename: "system_board_climbs.csv",
      headers: %w[date board climb_name grade setter angle attempts is_send is_benchmark comment]
    }
  }.freeze

  def initialize(user:)
    @user = user
  end

  def to_json
    records = grouped_records
    activities = []

    records.each do |type, items|
      items.each do |log, loggable|
        activities << build_hash(type, log, loggable)
      end
    end

    activities.sort_by! { |a| a[:date] }
    JSON.pretty_generate(activities)
  end

  def to_csv_zip
    records = grouped_records

    buffer = Zip::OutputStream.write_buffer do |zip|
      CSV_SCHEMAS.each do |type, schema|
        items = records[type] || []
        next if items.empty?

        csv_data = CSV.generate do |csv|
          csv << schema[:headers]
          items.each do |log, loggable|
            csv << csv_row(type, log, loggable)
          end
        end

        zip.put_next_entry(schema[:filename])
        zip.write(csv_data)
      end
    end

    buffer.string
  end

  private

  def grouped_records
    logs = ActivityLog
      .where(user: @user)
      .includes(loggable: [])
      .order(performed_at: :asc)

    board_climb_ids = []
    exercise_ids = []

    logs.each do |log|
      case log.loggable_type
      when "BoardClimb" then board_climb_ids << log.loggable_id
      when "Exercise" then exercise_ids << log.loggable_id
      end
    end

    problems_by_climb = BoardClimb.where(id: board_climb_ids).includes(:problem).index_by(&:id)
    exercises_with_types = Exercise.where(id: exercise_ids).includes(:exercise_type).index_by(&:id)

    records = Hash.new { |h, k| h[k] = [] }

    logs.each do |log|
      loggable = case log.loggable_type
      when "BoardClimb" then problems_by_climb[log.loggable_id]
      when "Exercise" then exercises_with_types[log.loggable_id]
      else log.loggable
      end
      next unless loggable

      records[log.loggable_type] << [ log, loggable ]
    end

    records
  end

  def build_hash(type, log, loggable)
    base = { date: log.performed_at.to_date.iso8601, type: type.underscore }

    case type
    when "BoardClimb"
      base.merge(
        name: loggable.problem&.name,
        grade: loggable.problem&.grade,
        climb_type: loggable.climb_type,
        moves: loggable.number_of_moves,
        notes: loggable.notes
      )
    when "Exercise"
      base.merge(
        name: loggable.name,
        value: loggable.value,
        unit: loggable.unit,
        notes: loggable.notes
      )
    when "GymSession"
      base.merge(
        boulders: loggable.number_of_boulders,
        circuits: loggable.number_of_circuits,
        duration_minutes: loggable.duration_minutes,
        notes: loggable.notes
      )
    when "CragAscent"
      base.merge(
        route_name: loggable.route_name,
        grade: loggable.grade,
        ascent_type: loggable.ascent_type,
        gear_style: loggable.gear_style,
        crag: loggable.crag_name,
        country: loggable.country,
        partners: loggable.partners,
        source: loggable.source,
        notes: loggable.comment
      )
    when "SystemBoardClimb"
      base.merge(
        board: loggable.board,
        climb_name: loggable.climb_name,
        grade: loggable.displayed_grade,
        setter: loggable.setter_username,
        angle: loggable.angle,
        attempts: loggable.attempts,
        is_send: loggable.is_send,
        is_benchmark: loggable.is_benchmark,
        notes: loggable.comment
      )
    else
      base
    end.compact
  end

  def csv_row(type, log, loggable)
    date = log.performed_at.to_date.iso8601

    case type
    when "BoardClimb"
      [ date, loggable.problem&.name, loggable.problem&.grade,
        loggable.climb_type, loggable.number_of_moves, loggable.notes ]
    when "Exercise"
      [ date, loggable.name, loggable.value, loggable.unit, loggable.notes ]
    when "GymSession"
      [ date, loggable.number_of_boulders, loggable.number_of_circuits,
        loggable.duration_minutes, loggable.notes ]
    when "CragAscent"
      [ date, loggable.route_name, loggable.grade, loggable.ascent_type,
        loggable.gear_style, loggable.crag_name, loggable.country,
        loggable.partners, loggable.source, loggable.comment ]
    when "SystemBoardClimb"
      [ date, loggable.board, loggable.climb_name, loggable.displayed_grade,
        loggable.setter_username, loggable.angle, loggable.attempts,
        loggable.is_send, loggable.is_benchmark, loggable.comment ]
    end
  end
end
