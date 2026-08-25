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

  # Archive is the soft option: the rows survive, flagged away.
  test "archive discards the layout and its problems" do
    patch archive_board_board_layout_url(@board, @board_layout)

    assert_redirected_to board_path(@board)
    assert @board_layout.reload.discarded?
    assert problems(:one).reload.discarded?
    assert problems(:two).reload.discarded?
  end

  test "archive keeps the rows so nothing is actually lost" do
    assert_no_difference [ "BoardLayout.count", "Problem.count" ] do
      patch archive_board_board_layout_url(@board, @board_layout)
    end
  end

  # Delete means gone, and it takes the problems with it.
  test "delete destroys the layout and its problems" do
    assert_difference "BoardLayout.count", -1 do
      assert_difference "Problem.count", -2 do
        delete board_board_layout_url(@board, @board_layout)
      end
    end

    assert_redirected_to board_path(@board)
    assert_not BoardLayout.exists?(@board_layout.id)
  end

  test "archiving the active layout hands active to another one" do
    other = board_layouts(:two)

    patch archive_board_board_layout_url(@board, @board_layout)

    assert other.reload.active?
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
