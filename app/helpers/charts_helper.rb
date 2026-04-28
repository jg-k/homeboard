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

  def modern_bar_dataset
    {
      categoryPercentage: 0.65,
      barPercentage: 0.85
    }
  end
end
