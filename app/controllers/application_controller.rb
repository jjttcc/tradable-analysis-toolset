class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper

  def index
    @motd = MOTD.new
  end

end
