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
