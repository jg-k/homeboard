class ActivityCalendar
  def initialize(user, weeks: 52, start_date: nil, end_date: nil)
    @user = user
    @start_date = start_date || weeks.weeks.ago.to_date
    @end_date = end_date || Date.current
  end

  def summary_by_date
    Rails.cache.fetch(cache_key) { compute_summary }
  end

  private

  def compute_summary
    result = Hash.new { |h, k| h[k] = DayActivity.new }
    accumulate_board_climbs(result)
    accumulate_crag_ascents(result)
    accumulate_gym_sessions(result)
    accumulate_exercises(result)
    accumulate_hikes(result)
    result.default_proc = nil
    result
  end

  def cache_key
    [
      "activity_calendar/v1",
      @user.id,
      @start_date.to_s,
      @end_date.to_s,
      @user.activity_logs.cache_key_with_version
    ]
  end

  def range
    @start_date.beginning_of_day..@end_date.end_of_day
  end

  def accumulate_board_climbs(result)
    %w[BoardClimb SystemBoardClimb].each do |type|
      @user.activity_logs
           .where(loggable_type: type, performed_at: range)
           .group("DATE(performed_at)")
           .count
           .each do |date_str, count|
             date = parse_date(date_str)
             result[date].add(:board_climb, count: count, points: count * DayActivity::POINTS[:board_climb])
           end
    end
  end

  def accumulate_crag_ascents(result)
    @user.activity_logs
         .where(loggable_type: "CragAscent", performed_at: range)
         .group("DATE(performed_at)")
         .count
         .each do |date_str, count|
           date = parse_date(date_str)
           result[date].add(:crag_ascent, count: count, points: count * DayActivity::POINTS[:crag_ascent])
         end
  end

  def accumulate_gym_sessions(result)
    rows = @user.activity_logs
                .where(loggable_type: "GymSession", performed_at: range)
                .joins("INNER JOIN gym_sessions ON gym_sessions.id = activity_logs.loggable_id")
                .group(Arel.sql("DATE(activity_logs.performed_at)"))
                .pluck(
                  Arel.sql("DATE(activity_logs.performed_at)"),
                  Arel.sql("COUNT(activity_logs.id)"),
                  Arel.sql("COALESCE(SUM(gym_sessions.number_of_boulders), 0)"),
                  Arel.sql("COALESCE(SUM(gym_sessions.number_of_routes), 0)"),
                  Arel.sql("COALESCE(SUM(gym_sessions.number_of_circuits), 0)")
                )
    rows.each do |date_str, sessions, boulders, routes, circuits|
      date = parse_date(date_str)
      points = boulders.to_i * DayActivity::POINTS[:gym_boulder] +
               routes.to_i * DayActivity::POINTS[:gym_route] +
               circuits.to_i * DayActivity::POINTS[:gym_circuit]
      result[date].add(:gym_session, count: sessions.to_i, points: points)
    end
  end

  def accumulate_exercises(result)
    rows = @user.activity_logs
                .where(loggable_type: "Exercise", performed_at: range)
                .joins("INNER JOIN exercises ON exercises.id = activity_logs.loggable_id" \
                       " INNER JOIN exercise_types ON exercise_types.id = exercises.exercise_type_id")
                .group(Arel.sql("DATE(activity_logs.performed_at)"), "exercise_types.category")
                .count("activity_logs.id")
    rows.each do |(date_str, category), count|
      date = parse_date(date_str)
      per_log = category == "cardio" ? DayActivity::POINTS[:cardio_exercise] : DayActivity::POINTS[:exercise]
      result[date].add(:exercise, count: count, points: count * per_log)
    end
  end

  def accumulate_hikes(result)
    rows = @user.activity_logs
                .where(loggable_type: "Hike", performed_at: range)
                .joins("INNER JOIN hikes ON hikes.id = activity_logs.loggable_id")
                .group(Arel.sql("DATE(activity_logs.performed_at)"))
                .pluck(
                  Arel.sql("DATE(activity_logs.performed_at)"),
                  Arel.sql("COUNT(activity_logs.id)"),
                  Arel.sql("COALESCE(SUM(hikes.duration_hours), 0)"),
                  Arel.sql("SUM(CASE WHEN hikes.duration_hours IS NULL THEN 1 ELSE 0 END)")
                )
    rows.each do |date_str, hikes, total_hours, null_count|
      date = parse_date(date_str)
      hours = total_hours.to_f + null_count.to_i * DayActivity::DEFAULT_HIKE_HOURS
      points = (hours * DayActivity::POINTS[:hike_hour]).round
      result[date].add(:hike, count: hikes.to_i, points: points)
    end
  end

  def parse_date(value)
    value.is_a?(String) ? Date.parse(value) : value
  end
end
