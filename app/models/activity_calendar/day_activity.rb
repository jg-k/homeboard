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

    # Display priority for tie-break and tooltip ordering.
    CATEGORIES = %i[crag_ascent gym_session board_climb exercise hike].freeze

    CATEGORY_LABELS = {
      board_climb: "board climb",
      gym_session: "gym session",
      crag_ascent: "outdoor ascent",
      exercise: "exercise",
      hike: "hike"
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
      return nil unless any?
      max = @points_by_category.values.max
      tied = @points_by_category.select { |_, pts| pts == max }.keys
      tied.min_by { |c| CATEGORIES.index(c) || CATEGORIES.size }
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
