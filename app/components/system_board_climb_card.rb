class SystemBoardClimbCard < ActivityCard
  private

  def system_board_climb = loggable
  def kind = :"board-climb"
  def badge_label = system_board_climb.board.titleize

  def render_header
    if system_board_climb.is_send?
      render Badge.new(:green) { "Sent" }
    else
      render Badge.new(:yellow) { "Attempt" }
    end
    span(class: "activity-title") { system_board_climb.climb_name }
    if system_board_climb.displayed_grade.present?
      span(class: "text-sm text-gray font-medium") { system_board_climb.displayed_grade }
    end
  end

  def render_meta
    if system_board_climb.setter_username.present?
      span { "by #{system_board_climb.setter_username}" }
      span { " • " }
    end
    if system_board_climb.angle.present?
      span { "#{system_board_climb.angle}°" }
      span { " • " }
    end
    if attempts_present?
      span { attempts_text }
      span { " • " }
    end
    span { smart_date(@activity_log.performed_at) }
  end

  def notes = system_board_climb.comment

  def attempts_present?
    system_board_climb.attempts.present? && system_board_climb.attempts > 0
  end

  def attempts_text
    if system_board_climb.is_send? && system_board_climb.attempts == 1
      "Flashed"
    elsif system_board_climb.is_send?
      "Sent in #{system_board_climb.attempts} tries"
    else
      "#{system_board_climb.attempts} #{'try'.pluralize(system_board_climb.attempts)}"
    end
  end
end
