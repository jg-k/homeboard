class Measurement < ApplicationRecord
  belongs_to :metric

  validates :value, presence: true
  validates :recorded_at, presence: true

  delegate :name, :unit, :user, to: :metric
end

# == Schema Information
#
# Table name: measurements
#
#  id          :integer          not null, primary key
#  notes       :text
#  recorded_at :datetime         not null
#  value       :decimal(, )      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  metric_id   :integer          not null
#
# Indexes
#
#  index_measurements_on_metric_id                  (metric_id)
#  index_measurements_on_metric_id_and_recorded_at  (metric_id,recorded_at)
#
# Foreign Keys
#
#  metric_id  (metric_id => metrics.id)
#
