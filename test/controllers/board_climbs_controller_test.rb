require "test_helper"

class BoardClimbsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @board = boards(:one)
    @problem = problems(:one)
  end

  # The page renders the form twice, for the mobile and desktop layouts.
  test "the log form asks for the date, then attempts, then offers one button per outcome" do
    get board_problem_path(@board, @problem)

    assert_response :success
    forms = css_select(".board-climb-section form")
    assert_equal 2, forms.size
    forms.each do |form|
      fields = form.css("input[name='board_climb[climbed_at]'], input[name='board_climb[attempts]'], .climb-log-actions")
      assert_equal [ "datetime-local", "number", "climb-log-actions" ], fields.map { _1["type"] || _1["class"] }

      buttons = form.css(".climb-log-actions button[type=submit][name='board_climb[climb_type]']")
      assert_equal [ %w[Attempt attempt], %w[Send sent], %w[Flash flash] ], buttons.map { [ _1.text, _1["value"] ] }
      assert_empty form.css("input[type=radio]")
    end
    assert_select "input[name='board_climb[attempts]'][value='1']"
  end

  test "the button pressed is the outcome logged" do
    %w[attempt sent flash].each do |outcome|
      post board_problem_board_climbs_path(@board, @problem),
           params: { board_climb: { climb_type: outcome, attempts: 3, climbed_at: "2026-10-20T18:30" } }

      climb = @problem.board_climbs.order(:id).last
      assert_equal outcome, climb.climb_type
      assert_equal 3, climb.attempts
      assert_redirected_to board_problem_path(@board, @problem)
    end
  end

  test "a circuit problem logs moves with a single button" do
    @problem.update_column(:circuit, true)

    get board_problem_path(@board, @problem)

    assert_select ".board-climb-section input[name='board_climb[number_of_moves]']"
    assert_select ".board-climb-section button[value=circuit]", text: "Log circuit"
    assert_select ".climb-log-actions", false
  end
end
