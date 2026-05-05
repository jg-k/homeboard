class ActivityLog::Loggables
  LOADERS = {
    board_climb: ->(ids) {
      BoardClimb.joins(:problem).merge(Problem.with_discarded)
                .includes(problem: { board_layout: :board })
                .where(id: ids).index_by(&:id)
    },
    exercise: ->(ids) { Exercise.includes(:exercise_type).where(id: ids).index_by(&:id) },
    gym_session: ->(ids) { GymSession.where(id: ids).index_by(&:id) },
    crag_ascent: ->(ids) { CragAscent.where(id: ids).index_by(&:id) },
    system_board_climb: ->(ids) { SystemBoardClimb.where(id: ids).index_by(&:id) },
    hike: ->(ids) { Hike.where(id: ids).index_by(&:id) }
  }.freeze

  def self.for(activity_logs)
    LOADERS.each_with_object({}) do |(kind, loader), result|
      ids = activity_logs.select { |log| log.public_send("#{kind}?") }.map(&:loggable_id)
      result[kind] = ids.any? ? loader.call(ids) : {}
    end
  end

  def self.preload(activity_logs)
    by_kind = self.for(activity_logs)
    activity_logs.each_with_object({}) do |log, result|
      result[log.id] = by_kind.dig(log.loggable_type.underscore.to_sym, log.loggable_id)
    end
  end
end
