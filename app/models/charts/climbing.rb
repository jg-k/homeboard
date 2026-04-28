class Charts::Climbing
  def initialize(user, weeks: 12)
    @user = user
    @weeks = weeks
    @start_date = (weeks - 1).weeks.ago.beginning_of_week
    @weeks_range = Charts::Week.range(from: @start_date, count: weeks)
  end

  def series
    [
      { name: "Board", data: series_for(board_climbs) },
      { name: "Kilter", data: series_for(kilter_climbs) },
      { name: "Indoor Climbing", data: series_for(gym_climbs) },
      { name: "Outdoor", data: series_for(outdoor_climbs) }
    ]
  end

  private

  def series_for(counts)
    @weeks_range.map { |week| [ week.label, counts[week.key] || 0 ] }
  end

  def board_climbs
    BoardClimb.joins(:activity_log)
              .where(activity_logs: { user_id: @user.id })
              .where(climbed_at: @start_date..)
              .group("strftime('%Y-%W', climbed_at)")
              .sum(:attempts)
  end

  def kilter_climbs
    SystemBoardClimb.joins(:activity_log)
                    .where(activity_logs: { user_id: @user.id })
                    .where(board: %w[kilter boardsesh_kilter])
                    .where(climbed_at: @start_date..)
                    .group("strftime('%Y-%W', climbed_at)")
                    .sum("COALESCE(attempts, 0) + CASE WHEN is_send = 1 THEN 1 ELSE 0 END")
  end

  def gym_climbs
    GymSession.joins(:activity_log)
              .where(activity_logs: { user_id: @user.id })
              .where(activity_logs: { performed_at: @start_date.. })
              .group("strftime('%Y-%W', activity_logs.performed_at)")
              .sum("COALESCE(number_of_boulders, 0) + COALESCE(number_of_circuits, 0)")
  end

  def outdoor_climbs
    CragAscent.joins(:activity_log)
              .where(activity_logs: { user_id: @user.id })
              .where(ascent_date: @start_date..)
              .group("strftime('%Y-%W', ascent_date)")
              .count
  end
end
