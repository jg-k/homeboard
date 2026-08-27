# How many goes a route took: every ascent the climber logged on it, up to and
# including the one that sent it.
class CragAscent::RouteAttempts
  # A tick claims no style and a clean allows rests, but both mean the climber
  # got up it. Only an attempt or a hang dog says they did not.
  SENDS = %w[onsight flash redpoint pink_point send clean tick].freeze

  def initialize(user:, thecrag_route_id:)
    @user = user
    @thecrag_route_id = thecrag_route_id.to_s
  end

  # Nil while the route is still a project: there is nothing to count up to.
  def count
    return nil unless sent?

    ascents.where(ascent_date: ..send_ascent.ascent_date).count
  end

  def sent?
    send_ascent.present?
  end

  def send_ascent
    @send_ascent ||= ascents.where(ascent_type: SENDS).order(:ascent_date).first
  end

  def ascents
    CragAscent.logged_by(@user).where(thecrag_route_id: @thecrag_route_id)
  end
end
