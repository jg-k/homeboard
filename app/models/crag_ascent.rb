class CragAscent < ApplicationRecord
  has_one :activity_log, as: :loggable, dependent: :destroy

  enum :ascent_type, {
    onsight: "onsight",
    flash: "flash",
    redpoint: "redpoint",
    send: "send",
    tick: "tick",
    attempt: "attempt",
    hang_dog: "hang_dog",
    clean: "clean",
    pink_point: "pink_point"
  }, prefix: true

  enum :gear_style, {
    sport: "sport",
    trad: "trad",
    boulder: "boulder"
  }, prefix: true

  validates :route_name, presence: true
  validates :ascent_date, presence: true
  validates :thecrag_ascent_id, uniqueness: true, allow_nil: true
end

# == Schema Information
#
# Table name: crag_ascents
#
#  id                :integer          not null, primary key
#  ascent_date       :datetime         not null
#  ascent_type       :string
#  comment           :text
#  country           :string
#  crag_name         :string
#  crag_path         :string
#  gear_style        :string
#  grade             :string
#  partners          :string
#  quality           :integer
#  route_height      :integer
#  route_name        :string           not null
#  source            :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  thecrag_ascent_id :string
#
# Indexes
#
#  index_crag_ascents_on_thecrag_ascent_id  (thecrag_ascent_id) UNIQUE WHERE thecrag_ascent_id IS NOT NULL
#
