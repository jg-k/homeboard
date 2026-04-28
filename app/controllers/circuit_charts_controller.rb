class CircuitChartsController < ApplicationController
  before_action :authenticate_user!

  def show
    @board = current_user.boards.kept.find(params[:board_id])
    @problem = @board.problems.kept.find(params[:problem_id])
    @chart_data = @problem.circuit_chart_data(current_user)
  end
end
