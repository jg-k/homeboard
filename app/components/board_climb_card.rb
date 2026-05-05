class BoardClimbCard < ActivityCard
  private

  def board_climb = loggable
  def kind = :"board-climb"
  def badge_label = "Board climb"

  def render_header
    render Badge.new(climb_type_color, size: :base) { board_climb.climb_type.titleize }
    if board_climb.attempts > 1
      span(class: "text-sm text-gray") { "#{board_climb.attempts} attempts" }
    end
    if board_climb.number_of_moves.present?
      span(class: "text-sm text-gray") { "#{board_climb.number_of_moves} moves" }
    end
    span(class: "activity-title") do
      plain board_climb.problem.name
      if board_climb.problem.discarded?
        plain " "
        span(class: "text-muted") { "(deleted)" }
      end
    end
    span(class: "text-sm text-gray font-medium") { board_climb.problem.grade }
    return unless board_climb.circuit?

    link_to board_problem_circuit_chart_path(board_climb.problem.board_layout.board, board_climb.problem),
      class: "btn-icon",
      title: "View circuit progress",
      data: { turbo_frame: "_top" } do
      icon(:bar_chart)
    end
  end

  def render_meta
    span(class: "font-medium") { board_climb.problem.board_layout.board.name }
    span { " • " }
    span { smart_date(@activity_log.performed_at) }
  end

  def notes = board_climb.notes

  def activity_actions
    @activity_actions ||= ActivityActions.new(
      edit_path: edit_board_problem_board_climb_path(board_climb.problem.board_layout.board, board_climb.problem, board_climb),
      delete_path: board_problem_board_climb_path(board_climb.problem.board_layout.board, board_climb.problem, board_climb),
      delete_confirm: "Are you sure you want to delete this board climb?"
    )
  end

  def climb_type_color
    return :purple if board_climb.flash?
    return :green if board_climb.sent?
    return :blue if board_climb.circuit?

    :yellow
  end
end
