require 'ruby_contracts'

class PagesController < ApplicationController
  include Contracts::DSL

  def set_appname
    @appname = Rails.configuration.application_name
  end

  HOME_TITLE = 'Home'
  ABOUT_TITLE = 'About'
  HELP_TITLE = 'Help'

  post :user_if_signed_in do implies(signed_in?, current_user != nil) end
  post :mclient_if_signed_in do implies(signed_in?, @mas_client != nil) end
  def home
    @title = HOME_TITLE
    set_appname
    @motd = MOTD.new
    if signed_in?
      @mas_client = mas_client(current_user)
      @mas_client.request_symbols
      symbol_list = @mas_client.symbols
      if symbol_list.length > 0
        @mas_client.request_period_types(symbol_list.first)
      end
    end
  end

#!!!!!TO-DO: Is this action needed?
  def show
    redirect_to charts_index_path
  end

  def about
    @title = ABOUT_TITLE
    set_appname
    @motd = MOTD.new
  end

  def help
    @title = HELP_TITLE
    set_appname
    @motd = MOTD.new
  end

end
