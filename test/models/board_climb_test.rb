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
require "test_helper"

class BoardClimbTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
