class ProblemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_board, except: [ :landing ]
  before_action :set_problem, only: [ :show, :edit, :update, :soft_delete ]
  before_action :load_navigation_data, except: [ :landing, :create, :update, :soft_delete ]

  def landing
    board = current_user.boards.kept.joins(:problems).merge(Problem.kept).order(:name).first
    board ||= current_user.boards.kept.order(:name).first
    if board
      redirect_to board_problems_path(board)
    else
      redirect_to getting_started_path
    end
  end

  def index
    @selected_problem = @problems.first
    set_problem_navigation
  end

  def show
    @selected_problem = @problem
    set_problem_navigation

    respond_to do |format|
      format.html do
        if turbo_frame_request?
          # Check if request came from mobile frame
          is_mobile = request.headers["Turbo-Frame"]&.include?("problem_detail_mobile")
          render partial: "problem_detail", locals: {
            problem: @selected_problem,
            show_nav: is_mobile,
            prev_problem: @prev_problem,
            next_problem: @next_problem,
            problem_position: @problem_position,
            problem_count: @problem_count
          }
        else
          render "index"
        end
      end
      format.json do
        render json: {
          id: @problem.id,
          name: @problem.name,
          grade: @problem.grade,
          grading_system_name: @board.grading_system&.name,
          board_layout_id: @problem.board_layout_id,
          created_at: @problem.created_at.strftime("%B %d, %Y"),
          start_holds: @problem.start_holds,
          finish_holds: @problem.finish_holds,
          hand_holds: @problem.hand_holds,
          foot_holds: @problem.foot_holds,
          prev_problem: @prev_problem ? { id: @prev_problem.id, board_layout_id: @prev_problem.board_layout_id, url: board_problem_path(@board, @prev_problem, filter_params) } : nil,
          next_problem: @next_problem ? { id: @next_problem.id, board_layout_id: @next_problem.board_layout_id, url: board_problem_path(@board, @next_problem, filter_params) } : nil,
          position: @problem_position,
          count: @problem_count
        }
      end
    end
  end

  def filter
    # Renders filter form
  end

  def new
    if params[:board_layout_id]
      @board_layout = @board.board_layouts.kept.find(params[:board_layout_id])
    else
      @board_layout = @board.active_layout
    end
    redirect_to board_problems_path(@board) and return unless @board_layout

    grading_system = @board.grading_system
    middle_grade = if grading_system&.grades&.any?
      grading_system.grades[grading_system.grades.length / 2]
    else
      "V0"
    end

    @problem = @board_layout.problems.build(
      name: random_problem_name,
      grade: middle_grade
    )

    @selected_problem = @problem
    @editing = true

    if turbo_frame_request?
      render partial: "problem_detail", locals: { problem: @selected_problem }
    else
      render "index"
    end
  end

  def create
    @board_layout = @board.board_layouts.kept.find(params[:board_layout_id])
    processed_params = problem_params

    @problem = @board_layout.problems.build(processed_params)
    @problem.created_by = current_user

    if @problem.save
      redirect_to board_problem_path(@board, @problem, filter_params), notice: "Problem was successfully created."
    else
      load_navigation_data
      @selected_problem = @problem
      @editing = true

      render "index", status: :unprocessable_entity
    end
  end

  def edit
    @selected_problem = @problem
    @editing = true
    set_problem_navigation

    if turbo_frame_request?
      render partial: "problem_detail", locals: { problem: @selected_problem }
    else
      render "index"
    end
  end

  def update
    processed_params = problem_params

    if @problem.update(processed_params)
      redirect_to board_problem_path(@board, @problem, filter_params), notice: "Problem was successfully updated."
    else
      load_navigation_data
      @selected_problem = @problem
      @editing = true

      render "index", status: :unprocessable_entity
    end
  end

  def soft_delete
    @problem.discard
    redirect_back fallback_location: @board, notice: "Problem was successfully deleted."
  end

  private

  def set_board
    @board = current_user.boards.kept.find(params[:board_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to problems_landing_path
  end

  def set_problem
    @problem = @board.problems.kept.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to board_problems_path(@board)
  end

  def load_navigation_data
    @boards = current_user.boards.kept.order(:name)
    @current_board = @board
    @problems = filtered_and_sorted_problems
  end

  def filtered_and_sorted_problems
    problems = @board.problems.kept.joins(:board_layout).merge(BoardLayout.not_archived).includes(:board_layout)

    # Apply filter
    case params[:filter]
    when "sent"
      problems = problems.sent_or_flashed_by(current_user)
    when "unsent"
      problems = problems.not_sent_by(current_user)
    end

    # Apply grade range filter
    if params[:min_grade].present? || params[:max_grade].present?
      grades = @board.grading_system&.grades || []
      if grades.any?
        min_index = params[:min_grade].present? ? grades.index(params[:min_grade]) : 0
        max_index = params[:max_grade].present? ? grades.index(params[:max_grade]) : grades.length - 1
        if min_index && max_index
          valid_grades = grades[min_index..max_index]
          problems = problems.where(grade: valid_grades)
        end
      end
    end

    # Apply sort
    case params[:sort]
    when "grade"
      problems.by_grade(:asc)
    when "grade_desc"
      problems.by_grade(:desc)
    else
      problems.by_date
    end
  end

  def set_problem_navigation
    return unless @selected_problem&.persisted?

    problems_array = @problems.to_a
    current_index = problems_array.index(@selected_problem)
    return unless current_index

    @problem_position = current_index + 1
    @problem_count = problems_array.size

    @prev_problem = problems_array[current_index - 1] if current_index > 0
    @next_problem = problems_array[current_index + 1]
  end

  def filter_params
    params.permit(:sort, :filter, :min_grade, :max_grade).to_h.compact_blank
  end

  helper_method :filter_params

  def random_problem_name
    adjectives = %w[Crimson Golden Silent Midnight Crystal Iron Velvet Frozen Burning Ancient Savage Electric Hollow Scarlet]
    nouns = %w[Summit Ridge Traverse Arete Face Wall Corner Pillar Spire Tower Ledge Crack Roof Chimney]
    animals = %w[Falcon Eagle Serpent Wolf Bear Lynx Raven Panther Viper Fox Cobra Hawk Stallion]
    "#{adjectives.sample} #{animals.sample} #{nouns.sample}"
  end

  def problem_params
    permitted = params.require(:problem).permit(:name, :grade, :circuit, :start_holds, :finish_holds, :hand_holds, :foot_holds)

    # Parse JSON strings back to arrays
    [ :start_holds, :finish_holds, :hand_holds, :foot_holds ].each do |hold_type|
      if permitted[hold_type].present?
        begin
          permitted[hold_type] = JSON.parse(permitted[hold_type])
        rescue JSON::ParserError
          permitted[hold_type] = []
        end
      else
        permitted[hold_type] = []
      end
    end

    permitted
  end
end
