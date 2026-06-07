class BoardLayoutsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_board
  before_action :set_board_layout, only: [ :update, :soft_delete, :archive, :image ]

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

  # Stable URL for the layout image. Serves the processed variant bytes
  # so cached responses survive Active Storage's signed-URL rotation.
  def image
    return head :not_found unless @board_layout.image_layout.attached?

    bytes = download_variant_bytes(@board_layout)
    return head :not_found if bytes.nil?

    response.headers["ETag"] = %("#{@board_layout.image_layout.blob.checksum}")
    expires_in 1.year, public: false
    send_data bytes,
              type: @board_layout.image_layout.blob.content_type,
              disposition: "inline"
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

  # Reads the processed variant bytes. If the variant file is missing on
  # disk (stale dev state), purge stale variant records so a later request
  # can re-process from the original, and serve the original blob's bytes
  # this time so the user still sees an image.
  def download_variant_bytes(layout)
    variant_bytes(layout.display_image.processed)
  rescue ActiveStorage::FileNotFoundError
    ActiveStorage::VariantRecord.where(blob_id: layout.image_layout.blob.id).destroy_all
    begin
      layout.image_layout.blob.download
    rescue ActiveStorage::FileNotFoundError
      nil
    end
  end

  def variant_bytes(variant)
    if variant.respond_to?(:image) && variant.image
      variant.image.download
    else
      variant.download
    end
  end
end
