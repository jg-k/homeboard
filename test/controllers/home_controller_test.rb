require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @board = boards(:one)
    @user_board = user_boards(:one)
    @board_layout = board_layouts(:one)
    @problem = problems(:one)
  end

  test "should render home when not signed in" do
    get root_url
    assert_response :success
  end

  test "should redirect to activity when signed in via home" do
    sign_in @user
    get root_url
    assert_redirected_to activity_path
  end

  test "problems landing should redirect to first board problems" do
    sign_in @user
    get problems_landing_url
    assert_redirected_to board_problems_path(@board)
  end

  test "should show problems index for board" do
    sign_in @user
    get board_problems_url(@board)
    assert_response :success
  end

  test "should show specific problem on board" do
    sign_in @user
    get board_problem_url(@board, @problem)
    assert_response :success
    assert_match @problem.name, response.body
    assert_match @problem.grade, response.body
    assert_match @board.name, response.body
    assert_match @board_layout.name, response.body
  end

  test "should show board tabs" do
    sign_in @user
    get board_problem_url(@board, @problem)
    assert_response :success
    assert_match @board.name, response.body
    assert_match "tab-active", response.body # Active tab styling
  end

  test "should show plus icon for creating new problems" do
    sign_in @user
    get board_problem_url(@board, @problem)
    assert_response :success
    assert_match "New Problem", response.body
    assert_match new_board_problem_path(@board, board_layout_id: @board_layout.id), response.body
  end

  test "should render empty state without problems" do
    sign_in @user
    Problem.destroy_all
    get board_problems_url(@board)
    assert_response :success
    assert_match "No problems yet", response.body
    assert_match "Create First Problem", response.body
  end

  test "should not show discarded problems" do
    sign_in @user
    @problem.discard
    get board_problems_url(@board)
    assert_response :success
    assert_no_match "Problem One", response.body
  end

  test "should show problems in descending order" do
    sign_in @user
    older_problem = problems(:two)
    older_problem.update!(created_at: 1.day.ago)

    get board_problem_url(@board, @problem)
    assert_response :success
    # Check that newer problem appears before older problem in the HTML
    assert response.body.index(@problem.name) < response.body.index(older_problem.name)
  end

  test "should redirect to board problems if accessing non-existent problem" do
    sign_in @user
    get board_problem_url(@board, 999999)
    assert_redirected_to board_problems_path(@board)
  end

  test "should not allow accessing another user's board" do
    sign_in @user
    other_user = users(:two)
    other_board = Board.create!(name: "Other Board", description: "Other")
    UserBoard.create!(user: other_user, board: other_board)

    # Should redirect to problems landing when trying to access another user's board
    get board_problems_url(other_board)
    assert_redirected_to problems_landing_path
  end

  test "should not allow accessing another user's problem" do
    sign_in @user
    other_user = users(:two)
    other_board = Board.create!(name: "Other Board", description: "Other")
    UserBoard.create!(user: other_user, board: other_board)

    other_layout = BoardLayout.create!(board: other_board, name: "Other Layout", use_sample_image: "1")
    other_problem = Problem.create!(board_layout: other_layout, name: "Other Problem", grade: "V1", start_holds: [ { x: 0.1, y: 0.1 } ])

    # Should redirect to problems landing when trying to access another user's problem
    get board_problem_url(other_board, other_problem)
    assert_redirected_to problems_landing_path
  end

  test "should require authentication for problems landing" do
    get problems_landing_url
    assert_redirected_to new_user_session_url
  end

  test "should require authentication for board problems" do
    get board_problems_url(@board)
    assert_redirected_to new_user_session_url
  end

  test "root path works for both authenticated and unauthenticated" do
    get root_url
    assert_response :success

    sign_in @user
    get root_url
    assert_redirected_to activity_path
  end

  test "problems persist holds across all kinds" do
    sign_in @user
    @problem.update!(
      start_holds: [ { x: 0.1, y: 0.1 } ].to_json,
      finish_holds: [ { x: 0.9, y: 0.9 } ].to_json,
      hand_holds: [ { x: 0.5, y: 0.5 } ].to_json,
      foot_holds: [ { x: 0.3, y: 0.7 } ].to_json
    )

    assert_equal 4, @problem.holds.count
    assert_equal %w[finish foot hand start], @problem.holds.pluck(:kind).sort
  end

  test "board problems shows hold-marker controller attributes" do
    sign_in @user
    @problem.update!(
      start_holds: [ { x: 0.1, y: 0.1 } ].to_json,
      finish_holds: [ { x: 0.9, y: 0.9 } ].to_json
    )

    # Attach an image to the board layout
    @board_layout.image_layout.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_image.png")),
      filename: "test_image.png",
      content_type: "image/png"
    )

    get board_problem_url(@board, @problem)
    assert_response :success
    assert_match "data-controller=\"hold-marker", response.body
    assert_match "data-problem-data-start-holds-value", response.body
    assert_match "data-problem-data-finish-holds-value", response.body
  end

  test "should only show problems from current board" do
    sign_in @user
    # Create another board with problems
    other_board = Board.create!(name: "Other Board", description: "Another board")
    UserBoard.create!(user: @user, board: other_board)
    other_layout = BoardLayout.create!(board: other_board, name: "Other Layout", use_sample_image: "1")
    other_problem = Problem.create!(board_layout: other_layout, name: "Other Problem", grade: "V8", start_holds: [ { x: 0.1, y: 0.1 } ])

    get board_problem_url(@board, @problem)
    assert_response :success

    # Should show problems from current board
    assert_match @problem.name, response.body
    # Should NOT show problems from other boards
    assert_no_match other_problem.name, response.body
  end

  test "should show board without problems but with layouts" do
    sign_in @user
    Problem.destroy_all

    get board_problems_url(@board)
    assert_response :success
    assert_match "No problems yet", response.body
    assert_match "Create First Problem", response.body
    assert_match new_board_problem_path(@board, board_layout_id: @board_layout.id), response.body
  end

  test "should show board without layouts" do
    sign_in @user
    Problem.destroy_all
    BoardLayout.destroy_all

    get board_problems_url(@board)
    assert_response :success
    assert_match "No problems yet", response.body
    assert_match "Add Board Layout First", response.body
    assert_match board_path(@board), response.body
  end

  test "should show problems from all layouts in board" do
    sign_in @user
    # Create another layout for the same board
    inactive_layout = BoardLayout.create!(board: @board, name: "Inactive Layout", active: false, use_sample_image: "1")
    inactive_problem = Problem.create!(board_layout: inactive_layout, name: "Inactive Problem", grade: "V9", start_holds: [ { x: 0.1, y: 0.1 } ])

    get board_problem_url(@board, @problem)
    assert_response :success

    # Should show problems from all layouts
    assert_match @problem.name, response.body
    assert_match inactive_problem.name, response.body
  end

  test "should use active layout for create problem links" do
    sign_in @user
    # Create another layout - new layouts automatically become active
    new_layout = BoardLayout.create!(board: @board, name: "New Layout", use_sample_image: "1")

    get board_problem_url(@board, @problem)
    assert_response :success

    # Should link to the newest (now active) layout for creating problems
    assert_match new_board_problem_path(@board, board_layout_id: new_layout.id), response.body
  end

  test "should handle board with no active layout" do
    sign_in @user
    # Set all layouts to inactive
    @board.board_layouts.update_all(active: false)

    get board_problems_url(@board)
    assert_response :success
    # Should still show problems but no plus button for creating new ones
    assert_match @problem.name, response.body
  end

  test "should show delete button for problems" do
    sign_in @user
    get board_problem_url(@board, @problem)
    assert_response :success

    # Should have delete button next to edit link
    assert_match "Delete", response.body
    assert_match soft_delete_board_problem_path(@board, @problem), response.body
  end
end
