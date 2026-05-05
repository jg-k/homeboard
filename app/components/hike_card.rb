class HikeCard < ActivityCard
  private

  def hike = loggable
  def kind = :hike
  def badge_color = :purple
  def badge_label = "Hike"

  def render_header
    span(class: "activity-title") { hike.name }
  end

  def render_meta
    span { helpers.smart_date(@activity_log.performed_at) }
    span { "#{hike.distance_km} km" } if hike.distance_km.present?
    span { "#{hike.elevation_gain_m} m gain" } if hike.elevation_gain_m.present?
    span { "#{hike.duration_hours} hrs" } if hike.duration_hours.present?
  end

  def notes = hike.notes

  def activity_actions
    @activity_actions ||= ActivityActions.new(
      edit_path: edit_hike_path(hike),
      delete_path: hike_path(hike),
      delete_confirm: "Are you sure you want to delete this hike?",
      primary_action: { path: new_hike_path, title: "Log another hike", icon: :copy }
    )
  end
end
