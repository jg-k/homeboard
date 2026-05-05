class GymSessionCard < ActivityCard
  private

  def gym_session = loggable
  def kind = :"gym-session"
  def badge_color = :orange
  def badge_label = "Gym Session"

  def render_header
    span(class: "activity-title") { session_summary }
  end

  def render_meta
    span { smart_date(@activity_log.performed_at) }
  end

  def notes = gym_session.notes

  def activity_actions
    @activity_actions ||= ActivityActions.new(
      primary_action: {
        path: new_gym_session_path(
          number_of_boulders: gym_session.number_of_boulders,
          number_of_routes: gym_session.number_of_routes,
          number_of_circuits: gym_session.number_of_circuits,
          duration_minutes: gym_session.duration_minutes,
          notes: gym_session.notes
        ),
        title: "Duplicate to today",
        icon: :copy
      },
      edit_path: edit_gym_session_path(gym_session),
      delete_path: gym_session_path(gym_session),
      delete_confirm: "Are you sure you want to delete this activity?"
    )
  end

  def session_summary
    parts = []
    parts << pluralize(gym_session.number_of_boulders, "boulder") if gym_session.number_of_boulders.present?
    parts << pluralize(gym_session.number_of_routes, "route") if gym_session.number_of_routes.present?
    parts << pluralize(gym_session.number_of_circuits, "circuit") if gym_session.number_of_circuits.present?
    parts << "#{gym_session.duration_minutes} min" if gym_session.duration_minutes.present?
    parts.join(", ")
  end
end
