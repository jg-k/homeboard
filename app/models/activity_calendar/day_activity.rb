class ActivityCalendar
  class DayActivity
    POINTS = {
      board_climb: 1,
      gym_boulder: 1,
      gym_circuit: 1,
      gym_route: 2,
      crag_ascent: 4,
      exercise: 1,
      cardio_exercise: 2,
      hike_hour: 3
    }.freeze

    DEFAULT_HIKE_HOURS = 1

    # [bucket, minimum total points to reach it], evaluated top-down.
    INTENSITY_THRESHOLDS = [
      [ 5, 15 ],
      [ 4, 10 ],
      [ 3, 6 ],
      [ 2, 3 ],
      [ 1, 1 ]
    ].freeze

    # Display priority. The strongest thing you did names the day's colour, so a
    # board session with conditioning on top still reads as a board day however
    # many exercises were logged. Conditioning is last: it accompanies a day
    # rather than being one.
    CATEGORIES = %i[crag_ascent gym_session board_climb hike exercise].freeze

    CATEGORY_LABELS = {
      board_climb: "board climb",
      gym_session: "gym session",
      crag_ascent: "outdoor ascent",
      exercise: "exercise",
      hike: "hike"
    }.freeze

    # Legend order, and the wording the grid uses rather than the tooltip's.
    LEGEND_LABELS = {
      board_climb: "Board",
      exercise: "Conditioning",
      gym_session: "Indoor",
      crag_ascent: "Outdoor",
      hike: "Hike"
    }.freeze

    attr_reader :counts, :points_by_category

    def initialize
      @counts = Hash.new(0)
      @points_by_category = Hash.new(0)
    end

    def add(category, count:, points:)
      @counts[category] += count
      @points_by_category[category] += points
    end

    def any?
      @counts.values.any?(&:positive?)
    end

    def total_points
      @points_by_category.values.sum
    end

    def dominant_category
      CATEGORIES.find { |category| @counts[category].positive? }
    end

    def intensity
      return nil unless any?
      bucket = INTENSITY_THRESHOLDS.find { |_, min| total_points >= min }
      bucket ? bucket.first : 1
    end

    def css_class
      return "grid-day" unless any?
      "grid-day grid-day-#{dominant_category.to_s.tr('_', '-')} intensity-#{intensity}"
    end

    def tooltip(date)
      base = date.strftime("%b %d, %Y")
      return base unless any?
      parts = CATEGORIES.filter_map do |category|
        n = @counts[category]
        next if n.zero?
        label = CATEGORY_LABELS[category]
        "#{n} #{label}#{'s' if n != 1}"
      end
      "#{base}: #{parts.join(', ')}"
    end
  end
end
