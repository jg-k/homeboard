require "test_helper"

class CragAscent::RouteAttemptsTest < ActiveSupport::TestCase
  ROUTE = "15920929".freeze

  setup do
    @user = users(:two)
  end

  def log(type, on, route_id: ROUTE, user: @user)
    date = Time.zone.parse(on)
    ascent = CragAscent.create!(route_name: "Magic Flute", ascent_type: type,
                                ascent_date: date, thecrag_route_id: route_id)
    ascent.create_activity_log!(user: user, performed_at: date)
    ascent
  end

  def attempts(route_id: ROUTE, user: @user)
    CragAscent::RouteAttempts.new(user: user, thecrag_route_id: route_id)
  end

  test "counts every go up to and including the one that sent it" do
    log("attempt", "2026-05-01")
    log("hang_dog", "2026-05-03")
    log("attempt", "2026-05-08")
    log("redpoint", "2026-05-08")

    assert_equal 4, attempts.count
  end

  test "a route still being worked has no count yet" do
    log("attempt", "2026-05-01")
    log("hang_dog", "2026-05-03")

    assert_not attempts.sent?
    assert_nil attempts.count
  end

  # Repeats after the send say nothing about what it took to get it.
  test "goes logged after the send do not count" do
    log("attempt", "2026-05-01")
    log("redpoint", "2026-05-08")
    log("tick", "2026-06-20")

    assert_equal 2, attempts.count
  end

  test "the earliest send is the one measured to" do
    log("attempt", "2026-05-01")
    log("redpoint", "2026-05-08")
    log("flash", "2026-05-02")

    assert_equal Time.zone.parse("2026-05-02"), attempts.send_ascent.ascent_date
    assert_equal 2, attempts.count
  end

  test "another climber's goes on the same route are not ours" do
    log("attempt", "2026-05-01", user: users(:one))
    log("attempt", "2026-05-02")
    log("redpoint", "2026-05-03")

    assert_equal 2, attempts.count
  end

  test "goes on a different route do not count" do
    log("attempt", "2026-05-01", route_id: "999")
    log("redpoint", "2026-05-03")

    assert_equal 1, attempts.count
  end
end
