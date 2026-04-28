class Charts::Week
  FORMAT = "%Y-%W".freeze

  def self.range(from:, count:)
    (0...count).map { |i| new((from + i.weeks).strftime(FORMAT)) }
  end

  attr_reader :key

  def initialize(key)
    @key = key
  end

  def label
    year, week = @key.split("-").map(&:to_i)
    Date.commercial(year, week, 1).strftime("%b %d")
  end

  def ==(other)
    other.is_a?(self.class) && other.key == @key
  end
  alias_method :eql?, :==

  def hash
    @key.hash
  end
end
