class Hold < ApplicationRecord
  KINDS = %w[start finish hand foot].freeze

  belongs_to :problem

  validates :kind, presence: true, inclusion: { in: KINDS }
  validates :x, :y, presence: true, numericality: true

  scope :start, -> { where(kind: "start").order(:position) }
  scope :finish, -> { where(kind: "finish").order(:position) }
  scope :hand, -> { where(kind: "hand").order(:position) }
  scope :foot, -> { where(kind: "foot").order(:position) }

  def to_marker
    { "x" => x, "y" => y, "id" => "db-#{id}" }
  end
end

# == Schema Information
#
# Table name: holds
#
#  id         :integer          not null, primary key
#  kind       :string           not null
#  position   :integer          default(0), not null
#  x          :float            not null
#  y          :float            not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  problem_id :integer          not null
#
# Indexes
#
#  index_holds_on_problem_id                        (problem_id)
#  index_holds_on_problem_id_and_kind_and_position  (problem_id,kind,position)
#
# Foreign Keys
#
#  problem_id  (problem_id => problems.id)
#
