class Charts::Exercise
  def initialize(user, period: Charts::Period.find(nil))
    @user = user
    @period = period
  end

  def series
    rows_by_category.sort.map do |category, rows|
      { name: category.titleize, data: @period.totals(rows.map { |performed_at, _| [ performed_at, 1 ] }) }
    end
  end

  private

  def rows_by_category
    Exercise.joins(:exercise_type, :activity_log)
            .where(exercise_types: { user_id: @user.id })
            .where(activity_logs: { performed_at: @period.starts_at.. })
            .pluck("activity_logs.performed_at", "exercise_types.category")
            .group_by(&:last)
  end
end
