class CragAscentCard < ActivityCard
  private

  def crag_ascent = loggable
  def kind = :"crag-ascent"
  def badge_label = "Outdoor"

  def render_header
    if crag_ascent.ascent_type.present?
      render Badge.new(ascent_badge_color) { crag_ascent.ascent_type.titleize }
    end
    if crag_ascent.gear_style.present?
      render Badge.new(:blue) { crag_ascent.gear_style.titleize }
    end
    span(class: "activity-title") { crag_ascent.route_name }
    if crag_ascent.grade.present?
      span(class: "text-sm text-gray font-medium") { crag_ascent.grade }
    end
  end

  def render_meta
    if crag_ascent.crag_name.present?
      span(class: "font-medium") { crag_ascent.crag_name }
      span { " • " }
    end
    span { smart_date(@activity_log.performed_at) }
  end

  def notes = crag_ascent.comment

  def activity_actions
    @activity_actions ||= ActivityActions.new(
      delete_path: crag_ascent_path(crag_ascent),
      delete_confirm: "Are you sure you want to delete this outdoor ascent?"
    )
  end

  def ascent_badge_color
    case crag_ascent.ascent_type
    when "onsight", "flash" then :purple
    when "redpoint", "send" then :green
    when "attempt", "hang_dog" then :yellow
    else :gray
    end
  end
end
