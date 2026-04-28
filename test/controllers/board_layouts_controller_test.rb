require "test_helper"

class BoardLayoutsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @board = boards(:one)
    @board_layout = board_layouts(:one)
    sign_in @user
  end

  test "should create board layout" do
    assert_difference("BoardLayout.count") do
      post board_board_layouts_url(@board), params: { board_layout: { name: "New Layout", use_sample_image: "1" } }
    end
    assert_redirected_to board_path(@board)
  end

  test "should update board layout" do
    patch board_board_layout_url(@board, @board_layout), params: { board_layout: { name: "Updated Layout" } }
    assert_redirected_to board_path(@board)
  end

  test "should soft delete board layout" do
    patch soft_delete_board_board_layout_url(@board, @board_layout)
    assert_redirected_to board_path(@board)
    assert @board_layout.reload.discarded?
  end
end
