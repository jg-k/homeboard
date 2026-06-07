class PagesController < ApplicationController
  before_action :authenticate_user!, except: :offline

  def getting_started
  end

  def offline
  end
end
