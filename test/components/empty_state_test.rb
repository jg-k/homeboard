require "test_helper"

class EmptyStateTest < ActiveSupport::TestCase
  test "renders a title and description" do
    html = EmptyState.new(title: "No boards found", description: "Create a board.").call

    assert_equal %(<div class="empty-state"><h3>No boards found</h3><p>Create a board.</p></div>), html
  end

  test "leaves out the description and actions when not given" do
    assert_equal %(<div class="empty-state"><h3>No activity yet</h3></div>), EmptyState.new(title: "No activity yet").call
  end

  test "wraps the block in an actions row" do
    html = EmptyState.new(title: "No boards found").call { |c| c.a(href: "/boards/new") { "New board" } }

    assert_includes html, %(<div class="empty-state-actions"><a href="/boards/new">New board</a></div>)
  end
end
