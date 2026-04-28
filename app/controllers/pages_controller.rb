class PagesController < ApplicationController
  before_action :authenticate_user!

  def getting_started
  end
end
