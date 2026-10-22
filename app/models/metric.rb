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
