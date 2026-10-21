class Charts::Climbing
  def initialize(user, period: Charts::Period.find(nil))
    @user = user
    @period = period
    @from = period.starts_at
  end

  def series
    [
      { name: "Board", data: @period.totals(board_climbs) },
      { name: "Kilter", data: @period.totals(kilter_climbs) },
      { name: "Indoor Climbing", data: @period.totals(gym_climbs) },
      { name: "Outdoor", data: @period.totals(outdoor_climbs) }
    ]
  end

  private

  def board_climbs
    BoardClimb.joins(:activity_log)
              .where(activity_logs: { user_id: @user.id })
              .where(climbed_at: @from..)
              .pluck(:climbed_at, :attempts)
  end

  def kilter_climbs
    SystemBoardClimb.joins(:activity_log)
                    .where(activity_logs: { user_id: @user.id })
                    .where(board: %w[kilter boardsesh_kilter])
                    .where(climbed_at: @from..)
                    .pluck(:climbed_at, Arel.sql("COALESCE(attempts, 0) + CASE WHEN is_send = 1 THEN 1 ELSE 0 END"))
  end

  def gym_climbs
    GymSession.joins(:activity_log)
              .where(activity_logs: { user_id: @user.id, performed_at: @from.. })
              .pluck("activity_logs.performed_at", Arel.sql("COALESCE(number_of_boulders, 0) + COALESCE(number_of_circuits, 0)"))
  end

  def outdoor_climbs
    CragAscent.joins(:activity_log)
              .where(activity_logs: { user_id: @user.id })
              .where(ascent_date: @from..)
              .pluck(:ascent_date, Arel.sql("1"))
  end
end
