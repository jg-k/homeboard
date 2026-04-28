module BoardLayoutsHelper
  def default_layout_name
    "#{current_season} spray"
  end

  private

  def current_season
    month = Date.current.month
    day = Date.current.day

    case month
    when 3
      day >= 20 ? "Spring" : "Winter"
    when 4, 5
      "Spring"
    when 6
      day >= 21 ? "Summer" : "Spring"
    when 7, 8
      "Summer"
    when 9
      day >= 22 ? "Autumn" : "Summer"
    when 10, 11
      "Autumn"
    when 12
      day >= 21 ? "Winter" : "Autumn"
    else
      "Winter"
    end
  end
end
