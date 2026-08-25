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
  setup do
    @board = boards(:one)
    @active = board_layouts(:one)
    @other = board_layouts(:two)
  end

  test "visible_layouts puts the active layout first" do
    assert_equal [ @active, @other ], @board.visible_layouts
  end

  test "visible_layouts orders the rest by recency behind the active one" do
    @active.update!(created_at: 1.day.ago)
    @other.update!(created_at: 2.days.ago)
    newest = @board.board_layouts.create!(name: "Newest", use_sample_image: "1")

    assert_equal [ newest, @active, @other ], @board.visible_layouts
  end

  test "visible_layouts leaves out archived layouts, which are soft deleted" do
    @other.archive!

    assert_equal [ @active ], @board.visible_layouts
  end

  test "visible_layouts leaves out deleted layouts" do
    @other.discard

    assert_equal [ @active ], @board.visible_layouts
  end

  test "problems_by_layout groups kept problems under their layout, by name" do
    assert_equal({ @active.id => [ problems(:one), problems(:two) ] }, @board.problems_by_layout)

    problems(:one).discard
    assert_equal({ @active.id => [ problems(:two) ] }, @board.problems_by_layout)
  end
end
