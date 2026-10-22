require "test_helper"

class FormErrorsTest < ActiveSupport::TestCase
  test "renders nothing when the record is valid" do
    assert_equal "", FormErrors.new(Board.new).call
  end

  test "lists every error under a heading named after the model" do
    board = Board.new
    board.errors.add(:name, :blank)
    board.errors.add(:description, :too_long, count: 10)

    html = FormErrors.new(board).call

    assert_includes html, %(<div class="form-errors">)
    assert_includes html, "2 errors prohibited this board from being saved:"
    assert_includes html, "<li>Name can&#39;t be blank</li>"
    assert_includes html, "<li>Description is too long (maximum is 10 characters)</li>"
  end

  test "takes a noun to override the model name" do
    hike = Hike.new
    hike.errors.add(:name, :blank)

    assert_includes FormErrors.new(hike, noun: "activity").call, "1 error prohibited this activity from being saved:"
  end
end
