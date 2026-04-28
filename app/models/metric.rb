class Metric < ApplicationRecord
  belongs_to :user

  has_many :measurements, dependent: :destroy
  has_many :targets, as: :targetable, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :unit, presence: true

  attr_accessor :initial_target

  def chart_data
    measurements.order(:recorded_at)
                .pluck(:recorded_at, :value)
                .map { |recorded_at, value| [ recorded_at.to_date.iso8601, value.to_f ] }
  end

  def current_target
    targets.first
  end

  def chart_data_with_targets
    metric_data = chart_data
    target_data = build_target_staircase(metric_data)

    return metric_data if target_data.empty?

    [
      { name: name, data: metric_data },
      { name: "Target", data: target_data }
    ]
  end

  private

  def build_target_staircase(metric_data)
    sorted_targets = targets.reorder(applicable_from: :asc)
    return [] if sorted_targets.empty? || metric_data.empty?

    today = Date.current
    data = []

    applicable_targets = sorted_targets.select { |t| t.applicable_from.to_date <= today }
    return [] if applicable_targets.empty?

    metric_start = Date.parse(metric_data.first.first)

    applicable_targets.each_with_index do |target, index|
      target_date = target.applicable_from.to_date

      if index == 0 && metric_start < target_date
        data << [ metric_start.to_datetime.beginning_of_day.iso8601, target.value.to_f ]
      end

      if index > 0
        prev_value = applicable_targets[index - 1].value.to_f
        just_before = target_date.to_datetime.beginning_of_day - 1.minute
        data << [ just_before.iso8601, prev_value ]
      end

      data << [ target_date.to_datetime.beginning_of_day.iso8601, target.value.to_f ]
    end

    last_date = Date.parse(data.last.first.to_s[0..9])
    data << [ today.to_datetime.end_of_day.iso8601, applicable_targets.last.value.to_f ] if last_date < today

    data
  end
end

# == Schema Information
#
# Table name: metrics
#
#  id         :integer          not null, primary key
#  category   :string           default("other"), not null
#  name       :string           not null
#  unit       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_metrics_on_user_id           (user_id)
#  index_metrics_on_user_id_and_name  (user_id,name) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
