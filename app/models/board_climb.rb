class BoardClimb < ApplicationRecord
  belongs_to :problem

  has_one :activity_log, as: :loggable, dependent: :destroy

  enum :climb_type, { attempt: "attempt", sent: "sent", flash: "flash", circuit: "circuit" }

  validates :climb_type, presence: true
  validates :climbed_at, presence: true

  before_validation :set_climbed_at, on: :create

  scope :chronological, -> { order(climbed_at: :desc) }
  scope :recent, -> { chronological.limit(20) }
  scope :successful, -> { where(climb_type: %w[sent flash]) }
  scope :for_user, ->(user) { joins(:activity_log).where(activity_logs: { user_id: user.id }) }

  private

  def set_climbed_at
    self.climbed_at ||= Time.current
  end
end

# == Schema Information
#
# Table name: board_climbs
#
#  id              :integer          not null, primary key
#  attempts        :integer          default(1), not null
#  climb_type      :string           not null
#  climbed_at      :datetime         not null
#  notes           :text
#  number_of_moves :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  problem_id      :integer          not null
#
# Indexes
#
#  index_board_climbs_on_problem_id                 (problem_id)
#  index_board_climbs_on_problem_id_and_climbed_at  (problem_id,climbed_at)
#
# Foreign Keys
#
#  problem_id  (problem_id => problems.id)
#
