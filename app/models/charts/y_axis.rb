class Charts::YAxis
  def self.range(series_data, padding_ratio: 0.15)
    values = extract_values(series_data)
    return {} if values.empty?

    min, max = values.minmax
    range = max - min
    padding = [ range * padding_ratio, max.abs * 0.02, 0.5 ].max

    {
      min: (min - padding).floor,
      max: (max + padding).ceil
    }
  end

  def self.extract_values(series_data)
    return [] if series_data.blank?

    if series_data.is_a?(Array) && series_data.first.is_a?(Hash)
      series_data.flat_map { |s| s[:data].to_a.map { |_, v| v } }
    else
      series_data.map { |_, v| v }
    end.compact.map(&:to_f)
  end
end
