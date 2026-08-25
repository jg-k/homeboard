require "test_helper"

class BoardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @board = boards(:one)
  end

  test "should get index" do
    get boards_url
    assert_response :success
  end

  test "index links each board through to its problems" do
    get boards_url

    assert_response :success
    assert_select "a[href=?]", board_problems_path(@board)
    assert_match "View 2 problems", response.body
  end

  # The index used to list every problem on every layout with a delete button
  # next to each one. It is a summary now.
  test "index summarises instead of listing every problem" do
    get boards_url

    assert_response :success
    assert_no_match(/Problem One/, response.body)
    assert_select "a[href=?]", soft_delete_board_problem_path(@board, problems(:one)), false
  end

  test "should get new" do
    get new_board_url
    assert_response :success
  end

  test "should create board" do
    assert_difference("Board.count") do
      post boards_url, params: { board: { description: @board.description, name: @board.name } }
    end

    assert_redirected_to board_problems_url(Board.last)
  end

  test "should show board" do
    get board_url(@board)
    assert_response :success
  end

  test "show links each layout through to its own problems" do
    get board_url(@board)

    assert_response :success
    assert_select "a[href=?]", board_problems_path(@board, board_layout_id: board_layouts(:one).id)
  end

  # Pinning a board for offline use belongs where you choose a board.
  test "the offline control lives on the index, wired per board" do
    get boards_url

    assert_response :success
    assert_select "[data-controller=board-offline][data-board-offline-board-id-value=?]", @board.id.to_s
    assert_select "[data-board-offline-manifest-path-value=?]",
      offline_manifest_board_path(@board, format: :json)

    get board_url(@board)
    assert_response :success
    assert_select "[data-controller=board-offline]", false
  end

  # Board-level actions live on the index card, not repeated here.
  test "show leaves edit and export to the boards index" do
    get board_url(@board)

    assert_response :success
    assert_select "a[href=?]", edit_board_path(@board), false
    assert_select "a[href=?]", export_board_path(@board, format: :pdf), false

    get boards_url
    assert_response :success
    assert_select "a[href=?]", edit_board_path(@board)
    assert_select "a[href=?]", export_board_path(@board, format: :pdf)
  end

  test "show offers archive and delete for each layout" do
    layout = board_layouts(:one)

    get board_url(@board)

    assert_response :success
    assert_select ".dropdown-menu form[action=?]", archive_board_board_layout_path(@board, layout)
    assert_select ".dropdown-menu form[action=?]", board_board_layout_path(@board, layout)
  end

  # The problems index hides its list below 1024px, so this is the only place
  # you can scan problems by name on a phone.
  test "show lists each layout's problems as links" do
    get board_url(@board)

    assert_response :success
    assert_select "a[href=?]", board_problem_path(@board, problems(:one)), text: /Problem One/
    assert_select "a[href=?]", board_problem_path(@board, problems(:two))
  end

  # Archiving is a soft delete now: the layout and its problems drop out of
  # both board pages entirely rather than lingering in a dimmed state.
  test "archived layouts and their problems leave both board pages" do
    board_layouts(:one).archive!

    get board_url(@board)
    assert_response :success
    assert_no_match(/Problem One/, response.body)
    assert_select "a[href=?]", board_problems_path(@board, board_layout_id: board_layouts(:one).id), false

    get boards_url
    assert_response :success
    assert_match "View 0 problems", response.body
  end

  test "should get edit" do
    get edit_board_url(@board)
    assert_response :success
  end

  test "should update board" do
    patch board_url(@board), params: { board: { description: @board.description, name: @board.name } }
    assert_redirected_to board_url(@board)
  end

  test "should destroy board" do
    assert_difference("Board.kept.count", -1) do
      delete board_url(@board)
    end

    assert_redirected_to boards_url
  end

  test "offline_manifest returns problems and layouts as JSON" do
    get offline_manifest_board_url(@board, format: :json)
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal @board.id, body["board_id"]
    assert body.key?("problems")
    assert body.key?("layouts")
    assert body.key?("csrf_token")
  end
end
