require "test_helper"

class ProblemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @board = boards(:one)
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
