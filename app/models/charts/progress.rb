# A line chart of one exercise type or metric over time, with its target as
# a dashed staircase. The viewer picks how far back to look and whether to
# plot every log or average them per day or week; the target line starts at
# the first plotted point, with whatever target was in force then.
class Charts::Progress
  RANGES = {
    "1m" => { label: "1 month", length: 1.month },
    "3m" => { label: "3 months", length: 3.months },
    "6m" => { label: "6 months", length: 6.months },
    "1y" => { label: "1 year", length: 1.year },
    "all" => { label: "All", length: nil }
  }.freeze
  GROUPINGS = {
    "each" => "Every log",
    "day" => "Daily average",
    "week" => "Weekly average"
  }.freeze

  # What the viewer picked, read from the query string. Unknown values fall
  # back to every log, all time: the chart as it looked before there was a
  # choice.
  Choice = Data.define(:range, :grouping) do
    def self.from(params)
      new(range: RANGES.key?(params[:range]) ? params[:range] : "all",
          grouping: GROUPINGS.key?(params[:grouping]) ? params[:grouping] : "each")
    end

    def to_h = { range: range, grouping: grouping }
  end

  attr_reader :choice

  # record is an ExerciseType or a Metric: anything with #name, #chart_data
  # and #targets.
  def initialize(record, choice: Choice.from({}), today: Date.current)
    @record = record
    @choice = choice
    @today = today
  end

  def series
    @series ||= begin
      lines = measured_series
      target = target_line(lines.flat_map { _1[:data] })
      target.empty? ? lines : lines + [ { name: "Target", data: target } ]
    end
  end

  def any? = series.any? { _1[:data].any? }
  def target? = series.last&.dig(:name) == "Target"

  private

  def starts_on
    length = RANGES.fetch(@choice.range)[:length]
    @today - length + 1.day if length
  end

  # chart_data is either one flat [[date, value], ...] list, or one hash per
  # added weight / rep count. Normalise to the latter.
  def measured_series
    raw = @record.chart_data
    raw = [ { name: @record.name, data: raw } ] unless raw.first.is_a?(Hash)

    raw.map { |s| s.merge(data: group(clip(s[:data]))) }.select { _1[:data].any? }
  end

  def clip(points)
    return points unless starts_on

    cutoff = starts_on.iso8601
    points.select { |date, _| date >= cutoff }
  end

  def group(points)
    return points if @choice.grouping == "each"

    points.group_by { |date, _| bucket(Date.iso8601(date)).iso8601 }
          .map { |date, rows| [ date, (rows.sum(&:last) / rows.size).round(2) ] }
  end

  def bucket(date) = @choice.grouping == "week" ? date.beginning_of_week : date

  def target_line(points)
    return [] if points.empty?

    in_force = @record.targets.reorder(applicable_from: :asc).select { _1.applicable_from.to_date <= @today }
    return [] if in_force.empty?

    start = Date.iso8601(points.map(&:first).min)
    current = in_force.reverse.find { _1.applicable_from.to_date <= start }
    later = in_force.select { _1.applicable_from.to_date > start }

    line = []
    line << [ start.beginning_of_day.iso8601, (current || later.first).value.to_f ]
    previous = current || later.first
    later.each do |target|
      next if target == previous

      changes_on = target.applicable_from.to_date.beginning_of_day
      line << [ (changes_on - 1.minute).iso8601, previous.value.to_f ]
      line << [ changes_on.iso8601, target.value.to_f ]
      previous = target
    end
    line << [ @today.end_of_day.iso8601, previous.value.to_f ]
  end
end
