class Board < ApplicationRecord
  include Discard::Model

  has_many :user_boards
  has_many :users, through: :user_boards
  belongs_to :grading_system, optional: true
  has_many :board_layouts, dependent: :destroy
  has_many :problems, through: :board_layouts

  accepts_nested_attributes_for :board_layouts, reject_if: :all_blank

  validates :name, presence: true

  def active_layout
    board_layouts.kept.find_by(active: true)
  end

  # Layouts worth showing, in the order the board reads: the one you are
  # climbing on first, then the rest by recency. Sorted in Ruby so a preloaded
  # association is reused.
  def visible_layouts
    board_layouts.reject(&:discarded?).sort_by do |layout|
      [ layout.active? ? 0 : 1, -layout.created_at.to_i ]
    end
  end

  # Kept problems grouped by the layout they live on, in one query, named so
  # you can scan for one. The board page lists these; counts fall out of it.
  def problems_by_layout
    problems.kept.order(:name).group_by(&:board_layout_id)
  end
end

# == Schema Information
#
# Table name: boards
#
#  id                :integer          not null, primary key
#  description       :text
#  discarded_at      :datetime
#  name              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  grading_system_id :integer
#
# Indexes
#
#  index_boards_on_discarded_at       (discarded_at)
#  index_boards_on_grading_system_id  (grading_system_id)
#
# Foreign Keys
#
#  grading_system_id  (grading_system_id => grading_systems.id)
#
