# How far back a chart looks, and how it buckets what it finds there. Short
# periods count per week; a year counts per month so the bars stay readable on
# a phone.
class Charts::Period
  PRESETS = {
    "4w" => { label: "4 weeks", bucket: :week, count: 4 },
    "3m" => { label: "3 months", bucket: :week, count: 13 },
    "6m" => { label: "6 months", bucket: :week, count: 26 },
    "1y" => { label: "1 year", bucket: :month, count: 12 }
  }.freeze
  DEFAULT = "3m".freeze

  Bucket = Data.define(:start, :label)

  def self.all = PRESETS.keys.map { new(_1) }

  # Unknown or missing keys fall back to the default, so a hand-edited query
  # param never empties the page.
  def self.find(key) = new(PRESETS.key?(key) ? key : DEFAULT)

  attr_reader :key

  def initialize(key, today: Date.current)
    @key = key
    @preset = PRESETS.fetch(key)
    @today = today
  end

  def label = @preset[:label]
  def bucket = @preset[:bucket]
  def to_param = key
  def ==(other) = other.is_a?(self.class) && other.key == key

  # Midnight at the start of the first bucket, for use in a where clause.
  def starts_at = buckets.first.start.beginning_of_day

  def buckets
    @buckets ||= begin
      step = bucket == :week ? 1.week : 1.month
      current = bucket_start(@today)
      (@preset[:count] - 1).downto(0).map do |i|
        start = current - (step * i)
        Bucket.new(start: start, label: start.strftime(bucket == :week ? "%b %d" : "%b %Y"))
      end
    end
  end

  def bucket_start(time)
    date = time.to_date
    bucket == :week ? date.beginning_of_week : date.beginning_of_month
  end

  # Turns [[time, value], ...] into [[label, total], ...] across every bucket,
  # with zeros where nothing happened.
  def totals(rows)
    sums = Hash.new(0)
    rows.each { |time, value| sums[bucket_start(time)] += value.to_i }
    buckets.map { |b| [ b.label, sums[b.start] ] }
  end
end
