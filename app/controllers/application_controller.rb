class ApplicationController < ActionController::Base
  protect_from_forgery

  def index
    @motd = MOTD.new
  end
end
