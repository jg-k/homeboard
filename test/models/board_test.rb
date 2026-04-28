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
require "test_helper"

class BoardTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
