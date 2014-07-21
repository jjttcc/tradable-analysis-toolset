class ApplicationController < ActionController::Base
  include SessionsHelper

  protect_from_forgery

  def index
    @motd = MOTD.new
  end
end
