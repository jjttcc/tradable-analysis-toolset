class PagesController < ApplicationController
  def home
    @title = "Home"
    @msg = MOTD.new.message
  end

  def about
    @title = "About"
    @msg = MOTD.new.message
  end
end
