module ChartsHelper
  CHART_PALETTE = [
    "rgba(0, 255, 255, 0.78)",
    "rgba(255, 0, 255, 0.78)",
    "rgba(255, 102, 0, 0.82)",
    "rgba(57, 255, 20, 0.78)",
    "rgba(191, 0, 255, 0.78)",
    "rgba(255, 255, 0, 0.78)"
  ].freeze

  AXIS_COLOR = "rgba(160, 160, 160, 0.7)".freeze
  GRID_COLOR = "rgba(160, 160, 160, 0.08)".freeze
  TOOLTIP_BG = "rgba(18, 18, 26, 0.95)".freeze

  def chart_palette
    CHART_PALETTE
  end

  def modern_column_chart_options(stacked: false)
    {
      responsive: true,
      maintainAspectRatio: false,
      animation: { duration: 600, easing: "easeOutCubic" },
      plugins: {
        legend: {
          position: "top",
          align: "end",
          labels: {
            color: AXIS_COLOR,
            usePointStyle: true,
            pointStyle: "circle",
            boxWidth: 6,
            boxHeight: 6,
            padding: 16,
            font: { size: 12 }
          }
        },
        tooltip: {
          backgroundColor: TOOLTIP_BG,
          titleColor: "#f0f0f0",
          bodyColor: "#d0d0d0",
          borderColor: "rgba(160, 160, 160, 0.2)",
          borderWidth: 1,
          padding: 10,
          cornerRadius: 6,
          boxPadding: 6,
          usePointStyle: true
        }
      },
      scales: {
        x: {
          stacked: stacked,
          border: { display: false },
          grid: { display: false },
          ticks: { color: AXIS_COLOR, font: { size: 11 }, maxRotation: 0, autoSkip: true }
        },
        y: {
          stacked: stacked,
          beginAtZero: true,
          border: { display: false },
          grid: { color: GRID_COLOR, drawTicks: false },
          ticks: { color: AXIS_COLOR, font: { size: 11 }, padding: 8 }
        }
      }
    }
  end

  PROGRESS_COLORS = [ "#14b8a6", "#3b82f6", "#a855f7", "#f97316", "#22c55e" ].freeze
  TARGET_COLOR = "#f59e0b".freeze

  # One line per series of a Charts::Progress, plus its target as a dashed
  # amber line when it has one.
  def progress_chart(progress, unit:, height: "300px")
    measured = progress.target? ? progress.series[0...-1] : progress.series
    colors = PROGRESS_COLORS.cycle.first(measured.size)
    colors << TARGET_COLOR if progress.target?
    datasets = measured.map { {} }
    datasets << { borderDash: [ 5, 5 ], pointRadius: 0 } if progress.target?

    line_chart progress.series,
               ytitle: unit,
               curve: false,
               height: height,
               colors: colors,
               library: {
                 spanGaps: true,
                 datasets: datasets,
                 scales: {
                   x: { ticks: { color: AXIS_COLOR }, grid: { color: GRID_COLOR } },
                   y: { ticks: { color: AXIS_COLOR }, grid: { color: GRID_COLOR }, **Charts::YAxis.range(progress.series) }
                 }
               }
  end

  # The range and grouping pickers above progress charts. The block builds
  # the link for a given { range:, grouping: }.
  def progress_controls(choice, &url_for)
    range_options = Charts::Progress::RANGES.map do |key, range|
      option = choice.with(range: key)
      SegmentedControl::Option.new(label: range[:label], url: url_for.call(option.to_h), active: option == choice)
    end
    grouping_options = Charts::Progress::GROUPINGS.map do |key, label|
      option = choice.with(grouping: key)
      SegmentedControl::Option.new(label: label, url: url_for.call(option.to_h), active: option == choice)
    end

    tag.div(class: "progress-controls") do
      safe_join([ render(SegmentedControl.new(label: "Look-back period", options: range_options)),
                  render(SegmentedControl.new(label: "Grouping", options: grouping_options)) ])
    end
  end

  def modern_bar_dataset
    {
      categoryPercentage: 0.65,
      barPercentage: 0.85
    }
  end
end
