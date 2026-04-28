class SystemBoardClimb < ApplicationRecord
  has_one :activity_log, as: :loggable, dependent: :destroy

  validates :uuid, presence: true, uniqueness: true
  validates :board, presence: true
  validates :climb_name, presence: true
  validates :climbed_at, presence: true
end

# == Schema Information
#
# Table name: system_board_climbs
#
#  id              :integer          not null, primary key
#  angle           :integer
#  attempts        :integer
#  board           :string           not null
#  climb_name      :string           not null
#  climb_uuid      :string
#  climbed_at      :datetime         not null
#  comment         :text
#  displayed_grade :string
#  is_benchmark    :boolean          default(FALSE)
#  is_mirror       :boolean          default(FALSE)
#  is_send         :boolean          default(TRUE), not null
#  quality         :integer
#  setter_username :string
#  uuid            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_system_board_climbs_on_uuid  (uuid) UNIQUE
#
