class ApplicationController < ActionController::Base
  protect_from_forgery

  def index
    @msg = MOTD.new.message
  end
end
