class Charts::Exercise
  def initialize(user, weeks: 12)
    @user = user
    @weeks = weeks
    @start_date = (weeks - 1).weeks.ago.beginning_of_week
    @weeks_range = Charts::Week.range(from: @start_date, count: weeks)
  end

  def series
    categories.map do |category|
      data = @weeks_range.map do |week|
        count = exercise_counts[[ category, week.key ]] || 0
        [ week.label, count ]
      end
      { name: category.titleize, data: data }
    end
  end

  private

  def categories
    exercise_counts.keys.map(&:first).uniq.sort
  end

  def exercise_counts
    @exercise_counts ||= Exercise.joins(:exercise_type, :activity_log)
                                 .where(exercise_types: { user_id: @user.id })
                                 .where(activity_logs: { performed_at: @start_date.. })
                                 .group("exercise_types.category", "strftime('%Y-%W', activity_logs.performed_at)")
                                 .count
  end
end
