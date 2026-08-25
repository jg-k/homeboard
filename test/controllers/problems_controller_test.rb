require "test_helper"

class ProblemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @board = boards(:one)
  end

  # Deleting a layout used to leave its problems in this list, orphaned under
  # something you could no longer see.
  test "index leaves out problems whose layout is gone" do
    board_layouts(:one).discard

    get board_problems_url(@board)

    assert_response :success
    assert_no_match(/Problem One/, response.body)
  end

  test "index narrows to one layout when given board_layout_id" do
    other_layout = board_layouts(:two)
    other_layout.problems.create!(name: "Only On Two", grade: "V2", start_holds: [ { x: 0.1, y: 0.1 } ])

    get board_problems_url(@board, board_layout_id: other_layout.id)

    assert_response :success
    assert_match "Only On Two", response.body
    assert_no_match(/Problem One/, response.body)
  end

  test "index keeps the layout filter alongside the other filter params" do
    get board_problems_url(@board, board_layout_id: board_layouts(:one).id, sort: "grade")

    assert_response :success
    assert_equal board_layouts(:one).id.to_s, offline_filter_applied["board_layout_id"]
  end

  # A bookmarked link to a layout that has since been deleted should still let
  # you start a problem, on whatever layout is active now.
  test "new falls back to the active layout when the given one is gone" do
    missing = board_layouts(:two)
    missing.discard

    get new_board_problem_url(@board, board_layout_id: missing.id)

    assert_response :success
  end

  test "filter form keeps the layout narrowing it arrived with" do
    layout = board_layouts(:one)

    get filter_board_problems_url(@board, board_layout_id: layout.id)

    assert_response :success
    assert_select "input[type=hidden][name=board_layout_id][value=?]", layout.id.to_s
  end

  test "index stamps the filter params the server actually applied" do
    get board_problems_url(@board, filter: "unsent", sort: "grade")

    assert_response :success
    applied = offline_filter_applied
    assert_equal "unsent", applied["filter"]
    assert_equal "grade", applied["sort"]
  end

  # The offline controller compares this stamp against the URL to decide
  # whether it is looking at a cached render. An unfiltered page must stamp
  # empty, not echo the query string back.
  test "index stamps empty when no filter is applied" do
    get board_problems_url(@board)

    assert_response :success
    assert_empty offline_filter_applied
  end

  test "index exposes the board grades so the client can resolve grade bounds" do
    v_scale = GradingSystem.create!(name: "V scale test", system_type: "built_in",
                                    grades: %w[V4 V5 V6 V7 V8])
    @board.update!(grading_system: v_scale)

    get board_problems_url(@board)

    assert_response :success
    grades = JSON.parse(css_value("[data-controller~='offline-filter']", "data-offline-filter-grades-value"))
    assert_equal v_scale.grades, grades
  end

  test "index renders the problem list inside the offline-filter target" do
    get board_problems_url(@board)

    assert_response :success
    assert_select "[data-offline-filter-target='list'] .problem-link", minimum: 1
  end

  test "problem links carry the data the client filter sorts and filters on" do
    get board_problems_url(@board)

    assert_response :success
    assert_select ".problem-link" do |links|
      links.each do |link|
        assert link["data-problem-id"].present?
        assert link["data-grade-index"].present?
        assert link["data-created-at"].present?
        assert_includes %w[true false], link["data-sent"]
      end
    end
  end

  test "detail frame exposes its problem id" do
    get board_problems_url(@board)

    assert_response :success
    ids = @board.problems.kept.pluck(:id).map(&:to_s)
    frames = css_select("[data-offline-filter-target='detail']")
    assert_equal 2, frames.size, "expected a desktop and a mobile detail frame"
    frames.each { |frame| assert_includes ids, frame["data-problem-id"] }
  end

  test "filter form stamps the applied params for offline rehydration" do
    get filter_board_problems_url(@board, filter: "sent", min_grade: "V4")

    assert_response :success
    applied = JSON.parse(css_value("[data-controller~='offline-filter-form']",
                                   "data-offline-filter-form-applied-value"))
    assert_equal "sent", applied["filter"]
    assert_equal "V4", applied["min_grade"]
  end

  # Prev/next must stay anchors even with nowhere to go, so the offline
  # controller has something to write an href onto when it re-navigates a
  # cached page.
  test "problem nav renders anchors for both directions" do
    attach_layout_image
    get board_problems_url(@board)

    assert_response :success
    assert_select "a[data-offline-filter-target='navPrev']", 1
    assert_select "a[data-offline-filter-target='navNext']", 1
    assert_select "[data-offline-filter-target='navPosition']", 1
  end

  private
    # The mobile nav only renders for layouts that have an image.
    def attach_layout_image
      board_layouts(:one).image_layout.attach(
        io: File.open(Rails.root.join("test/fixtures/files/test_image.png")),
        filename: "test_image.png",
        content_type: "image/png"
      )
    end

    def offline_filter_applied
      JSON.parse(css_value("[data-controller~='offline-filter']", "data-offline-filter-applied-value"))
    end

    def css_value(selector, attribute)
      node = css_select(selector).first
      assert node, "expected to find #{selector}"
      node[attribute]
    end
end
