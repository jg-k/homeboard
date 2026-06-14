class BoardsController < ApplicationController
  include BoardLayoutsHelper

  before_action :authenticate_user!
  before_action :set_board, only: %i[ show edit update destroy export offline_manifest ]

  # GET /boards or /boards.json
  def index
    @boards = current_user.boards.kept.includes(board_layouts: :problems)
  end

  # GET /boards/1 or /boards/1.json
  def show
  end

  # GET /boards/new
  def new
    default_system = current_user.default_grading_system || GradingSystem.built_in.first
    @board = Board.new(name: "Home woody", grading_system: default_system)
    @board.board_layouts.build(name: default_layout_name)
  end

  # GET /boards/1/edit
  def edit
  end

  # POST /boards or /boards.json
  def create
    @board = Board.new(board_params)

    respond_to do |format|
      if @board.save
        current_user.boards << @board
        format.html { redirect_to board_problems_path(@board), notice: "Board was successfully created." }
        format.json { render :show, status: :created, location: @board }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @board.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /boards/1 or /boards/1.json
  def update
    respond_to do |format|
      if @board.update(board_params)
        format.html { redirect_to @board, notice: "Board was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @board }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @board.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /boards/1 or /boards/1.json
  def destroy
    @board.discard

    respond_to do |format|
      format.html { redirect_to boards_path, notice: "Board was successfully deleted.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def soft_delete
    @board = current_user.boards.find(params[:id])
    @board.discard
    redirect_to boards_path, notice: "Board was successfully deleted."
  end

  def export
    pdf = BoardExport.new(@board, current_user).to_pdf
    send_data pdf, filename: "#{@board.name.parameterize}-problems.pdf", type: "application/pdf", disposition: "attachment"
  end

  def offline_manifest
    layouts = @board.board_layouts.kept.includes(image_layout_attachment: :blob)
    problems = Problem.kept.where(board_layout_id: layouts.map(&:id))

    render json: {
      board_id: @board.id,
      board_url: board_url(@board),
      generated_at: Time.current.to_i,
      csrf_token: form_authenticity_token,
      layouts: layouts.map { |l|
        {
          id: l.id,
          image_url: (l.image_layout.attached? ? image_board_board_layout_url(@board, l) : nil),
          image_etag: (l.image_layout.attached? ? l.image_layout.blob.checksum : nil)
        }
      },
      problems: problems.map { |p|
        {
          id: p.id,
          url: board_problem_url(@board, p),
          updated_at: p.updated_at.to_i
        }
      }
    }
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_board
      @board = current_user.boards.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def board_params
      params.require(:board).permit(:name, :description, :grading_system_id,
        board_layouts_attributes: [ :name, :image_layout, :use_sample_image ])
    end
end
