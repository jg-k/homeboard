class ActivityController < ApplicationController
  before_action :authenticate_user!

  def index
    @activity_data = ActivityCalendar.new(current_user).summary_by_date

    @pagy, @activity_logs = pagy(
      current_user.activity_logs.includes(loggable: []).chronological,
      limit: 30
    )

    @activity_logs_by_date = @activity_logs.group_by { |log| log.performed_at.to_date }
    assign_loggable_associations(@activity_logs)
  end

  def day
    @date = Date.parse(params[:date])
    @activity_logs = current_user.activity_logs
      .where(performed_at: @date.all_day)
      .includes(loggable: [])
      .chronological

    assign_loggable_associations(@activity_logs)
  end

  def history
    earliest = current_user.activity_logs.minimum(:performed_at)
    return redirect_to activity_path if earliest.nil?

    earliest_year = earliest.year
    current_year = Date.current.year

    all_data = ActivityCalendar.new(
      current_user,
      start_date: Date.new(earliest_year, 1, 1),
      end_date: Date.new(current_year, 12, 31)
    ).summary_by_date

    @years = (earliest_year..current_year).to_a.reverse.map do |year|
      start_date = Date.new(year, 1, 1)
      end_date = Date.new(year, 12, 31)
      year_data = all_data.select { |date, _| date.year == year }
      { year: year, data: year_data, start_date: start_date, end_date: end_date }
    end
  end

  private

  def assign_loggable_associations(activity_logs)
    @loggables_by_log_id = ActivityLog::Loggables.preload(activity_logs)
  end
end
