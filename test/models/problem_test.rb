# == Schema Information
#
# Table name: problems
#
#  id              :integer          not null, primary key
#  circuit         :boolean          default(FALSE), not null
#  discarded_at    :datetime
#  grade           :string
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  board_layout_id :bigint           not null
#  created_by_id   :integer
#
# Indexes
#
#  index_problems_on_board_layout_id  (board_layout_id)
#  index_problems_on_created_by_id    (created_by_id)
#  index_problems_on_discarded_at     (discarded_at)
#
# Foreign Keys
#
#  board_layout_id  (board_layout_id => board_layouts.id)
#  created_by_id    (created_by_id => users.id)
#
require "test_helper"

class ProblemTest < ActiveSupport::TestCase
  def setup
    @board = boards(:one)
    @board_layout = board_layouts(:one)
  end

  test "should not save problem without any holds" do
    problem = Problem.new(
      name: "Test Problem",
      grade: "V5",
      board_layout: @board_layout
    )

    assert_not problem.save
    assert_includes problem.errors[:base], "Problem must have at least one hold of any type"
  end

  test "should save problem with start holds" do
    problem = Problem.new(
      name: "Test Problem",
      grade: "V5",
      board_layout: @board_layout,
      start_holds: [ { x: 0.1, y: 0.1 } ]
    )

    assert problem.save
  end

  test "should save problem with finish holds" do
    problem = Problem.new(
      name: "Test Problem",
      grade: "V5",
      board_layout: @board_layout,
      finish_holds: [ { x: 0.9, y: 0.9 } ]
    )

    assert problem.save
  end

  test "should save problem with hand holds" do
    problem = Problem.new(
      name: "Test Problem",
      grade: "V5",
      board_layout: @board_layout,
      hand_holds: [ { x: 0.5, y: 0.5 } ]
    )

    assert problem.save
  end

  test "should save problem with foot holds" do
    problem = Problem.new(
      name: "Test Problem",
      grade: "V5",
      board_layout: @board_layout,
      foot_holds: [ { x: 0.3, y: 0.7 } ]
    )

    assert problem.save
  end

  test "should save problem with multiple hold types" do
    problem = Problem.new(
      name: "Test Problem",
      grade: "V5",
      board_layout: @board_layout,
      start_holds: [ { x: 0.1, y: 0.1 } ],
      finish_holds: [ { x: 0.9, y: 0.9 } ],
      hand_holds: [ { x: 0.5, y: 0.5 } ],
      foot_holds: [ { x: 0.3, y: 0.7 } ]
    )

    assert problem.save
  end
end
