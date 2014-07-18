class PagesController < ApplicationController
  def home
    @title = "Home"
    @motd = MOTD.new
  end

  def about
    @title = "About"
    @motd = MOTD.new
  end

  def help
    @title = "Help"
    @motd = MOTD.new
  end

end
