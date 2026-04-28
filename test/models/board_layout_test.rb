# == Schema Information
#
# Table name: board_layouts
#
#  id           :integer          not null, primary key
#  active       :boolean          default(FALSE), not null
#  archived_at  :datetime
#  discarded_at :datetime
#  name         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  board_id     :bigint           not null
#
# Indexes
#
#  index_board_layouts_on_board_id                    (board_id)
#  index_board_layouts_on_board_id_and_active_unique  (board_id,active) UNIQUE WHERE active = true AND discarded_at IS NULL
#  index_board_layouts_on_discarded_at                (discarded_at)
#
# Foreign Keys
#
#  board_id  (board_id => boards.id)
#
require "test_helper"

class BoardLayoutTest < ActiveSupport::TestCase
  def setup
    @board = boards(:one)
    @layout1 = board_layouts(:one)
    @layout2 = board_layouts(:two)
  end

  test "should have only one active layout per board" do
    assert @layout1.active?
    assert_not @layout2.active?

    # Try to make layout2 active
    @layout2.update!(active: true)

    # layout1 should now be inactive
    @layout1.reload
    assert_not @layout1.active?
    assert @layout2.active?
  end


  test "first layout should be active by default" do
    new_board = Board.create!(name: "New Board", description: "Test")
    new_layout = new_board.board_layouts.create!(name: "First Layout", use_sample_image: "1")

    assert new_layout.active?
  end

  test "new layout should become active and deactivate previous" do
    # layout1 is already active
    new_layout = @board.board_layouts.create!(name: "Second Layout", use_sample_image: "1")

    assert new_layout.active?
    # First layout should now be inactive
    @layout1.reload
    assert_not @layout1.active?
  end

  test "board should return active layout" do
    assert_equal @layout1, @board.active_layout
  end

  test "active scope should work" do
    active_layouts = BoardLayout.active
    assert_includes active_layouts, @layout1
    assert_not_includes active_layouts, @layout2
  end

  test "active_for_board class method should work" do
    assert_equal @layout1, BoardLayout.active_for_board(@board)
  end

  test "should handle discarded layouts" do
    # First deactivate and then discard the active layout
    @layout1.update!(active: false)
    @layout1.discard

    # Now make layout2 active (should work since layout1 is inactive and discarded)
    @layout2.update!(active: true)
    assert @layout2.active?

    # Board should return layout2 as active layout
    assert_equal @layout2, @board.active_layout
  end
end
