class Hike < ApplicationRecord
  has_one :activity_log, as: :loggable, dependent: :destroy

  validates :name, presence: true

  attr_accessor :performed_at
end

# == Schema Information
#
# Table name: hikes
#
#  id               :integer          not null, primary key
#  distance_km      :decimal(6, 2)
#  duration_hours   :decimal(4, 2)
#  elevation_gain_m :integer
#  name             :string           not null
#  notes            :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
