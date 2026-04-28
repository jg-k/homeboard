class BoardseshConnectionsController < ApplicationController
  def new
  end

  def create
    user_id = params[:user_id].to_s.strip

    if user_id.blank?
      flash.now[:alert] = "Please enter your Boardsesh user ID."
      return render :new, status: :unprocessable_entity
    end

    current_user.update!(boardsesh_user_id: user_id)

    redirect_to settings_path, notice: "Boardsesh account connected successfully"
  end

  def destroy
    current_user.update!(
      boardsesh_email: nil,
      boardsesh_session_token: nil,
      boardsesh_user_id: nil,
      boardsesh_last_synced_at: nil
    )

    redirect_to settings_path, notice: "Boardsesh account disconnected"
  end
end
