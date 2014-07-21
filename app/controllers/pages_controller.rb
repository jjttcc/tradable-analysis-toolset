class PagesController < ApplicationController
  def set_appname
    @appname = Rails.configuration.application_name
  end

  def home
    @title = "Home"
    set_appname
    @motd = MOTD.new
  end

  def about
    @title = "About"
    set_appname
    @motd = MOTD.new
  end

  def help
    @title = "Help"
    set_appname
    @motd = MOTD.new
  end

end
