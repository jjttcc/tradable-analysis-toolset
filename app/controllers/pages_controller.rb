class PagesController < ApplicationController
  def home
    @msg = MOTD.new.message
  end
end
