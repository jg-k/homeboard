class BoardClimbsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_board_and_problem

  def create
    @board_climb = @problem.board_climbs.build(board_climb_params)
    @board_climb.climbed_at ||= Time.current

    if @board_climb.save
      @board_climb.create_activity_log!(user: current_user, performed_at: @board_climb.climbed_at)
      redirect_to board_problem_path(@board, @problem),
                  notice: "Board climb logged successfully!"
    else
      redirect_to board_problem_path(@board, @problem),
                  alert: "Failed to log board climb: #{@board_climb.errors.full_messages.join(', ')}"
    end
  end

  def edit
    @board_climb = @problem.board_climbs.for_user(current_user).find(params[:id])
  end

  def update
    @board_climb = @problem.board_climbs.for_user(current_user).find(params[:id])

    if @board_climb.update(board_climb_params)
      @board_climb.activity_log.update!(performed_at: @board_climb.climbed_at)
      redirect_to activity_path, notice: "Board climb updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @board_climb = @problem.board_climbs.for_user(current_user).find(params[:id])
    @board_climb.destroy
    redirect_back fallback_location: board_problem_path(@board, @problem),
                  notice: "Board climb deleted successfully!"
  end

  private

  def set_board_and_problem
    @board = current_user.boards.find(params[:board_id])
    @problem = Problem.joins(board_layout: :board)
                      .where(board_layouts: { board_id: @board.id })
                      .find(params[:problem_id])
  end

  def board_climb_params
    params.require(:board_climb).permit(:climb_type, :notes, :climbed_at, :number_of_moves, :attempts)
  end
end
