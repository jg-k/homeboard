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

  # The sample photo was stored sideways; a board layout has to be portrait or
  # the hold markers land in the wrong place.
  test "the sample image is attached the right way up" do
    post board_board_layouts_url(@board), params: { board_layout: { name: "Sample Layout", use_sample_image: "1" } }

    attached = BoardLayout.order(:id).last.image_layout
    assert attached.attached?

    attached.blob.analyze
    metadata = attached.blob.reload.metadata
    assert_operator metadata["height"], :>, metadata["width"],
      "expected the sample layout image to be portrait"
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

  test "image action serves the layout image bytes" do
    @board.users << @user unless @board.users.include?(@user)
    @board_layout.image_layout.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test_image.png")),
      filename: "test_image.png",
      content_type: "image/png"
    )

    get image_board_board_layout_url(@board, @board_layout)
    assert_response :success
    assert_equal "image/png", response.media_type
    assert response.body.bytesize.positive?
  end

  test "image action returns 404 when no image attached" do
    @board.users << @user unless @board.users.include?(@user)
    get image_board_board_layout_url(@board, @board_layout)
    assert_response :not_found
  end
end
