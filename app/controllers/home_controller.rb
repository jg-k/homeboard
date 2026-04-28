class HomeController < ApplicationController
  def index
    return unless user_signed_in?

    if current_user.activity_logs.any?
      redirect_to activity_path
    elsif current_user.boards.kept.any?
      redirect_to problems_landing_path
    else
      redirect_to getting_started_path
    end
  end
end
