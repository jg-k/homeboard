class BoardLayoutsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_board
  before_action :set_board_layout, only: [ :update, :soft_delete, :archive ]

  def create
    @board_layout = @board.board_layouts.build(board_layout_params)

    use_sample = params[:board_layout][:use_sample_image] == "1"
    has_upload = params[:board_layout][:image_layout].present?

    unless use_sample || has_upload
      redirect_to @board, alert: "Please upload an image or use the sample image."
      return
    end

    if use_sample && !@board_layout.image_layout.attached?
      sample_path = Rails.root.join("app/assets/images/hb.jpg")
      @board_layout.image_layout.attach(
        io: File.open(sample_path),
        filename: "sample_layout.jpg",
        content_type: "image/jpeg"
      )
    end

    if @board_layout.save
      redirect_to @board, notice: "Layout was successfully created."
    else
      redirect_to @board, alert: "Error creating layout."
    end
  end

  def update
    if params[:board_layout].present? && @board_layout.update(board_layout_params)
      notice_message = if params[:board_layout][:active] == "true"
                        "Layout was set as active."
      else
                        "Layout was successfully updated."
      end
      redirect_to @board, notice: notice_message
    else
      redirect_to @board, alert: "Error updating layout."
    end
  end

  def soft_delete
    @board_layout.discard
    @board_layout.activate_next_if_needed!
    redirect_to @board, notice: "Layout was successfully deleted."
  end

  def archive
    @board_layout.toggle_archive!
    notice = @board_layout.archived? ? "Layout was archived." : "Layout was unarchived."
    redirect_to @board, notice: notice
  end

  private

  def set_board
    @board = current_user.boards.find(params[:board_id])
  end

  def set_board_layout
    @board_layout = @board.board_layouts.find(params[:id])
  end

  def board_layout_params
    params.require(:board_layout).permit(:name, :image_layout, :active)
  end
end
