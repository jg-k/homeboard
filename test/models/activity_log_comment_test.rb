require "test_helper"

class ActivityLogCommentTest < ActiveSupport::TestCase
  setup do
    @activity_log = activity_logs(:crag_ascent_one)
  end

  test "valid with body, category, activity_log" do
    comment = ActivityLogComment.new(activity_log: @activity_log, body: "Watch the loose hold on move 4", category: "safety")
    assert comment.valid?
  end

  test "requires body" do
    comment = ActivityLogComment.new(activity_log: @activity_log, category: "safety")
    assert_not comment.valid?
    assert_includes comment.errors[:body], "can't be blank"
  end

  test "requires category" do
    comment = ActivityLogComment.new(activity_log: @activity_log, body: "x")
    assert_not comment.valid?
    assert_includes comment.errors[:category], "can't be blank"
  end

  test "rejects unknown category" do
    comment = ActivityLogComment.new(activity_log: @activity_log, body: "x", category: "fancy")
    assert_not comment.valid?
    assert_includes comment.errors[:category], "is not included in the list"
  end

  test "destroyed with activity log" do
    comment = @activity_log.comments.create!(body: "note", category: "other")
    assert_difference "ActivityLogComment.count", -1 do
      @activity_log.destroy
    end
    assert_not ActivityLogComment.exists?(comment.id)
  end

  test "category_badge_color maps known categories" do
    assert_equal :red, ActivityLogComment.category_badge_color("safety")
    assert_equal :blue, ActivityLogComment.category_badge_color("obs")
    assert_equal :gray, ActivityLogComment.category_badge_color("other")
  end
end
