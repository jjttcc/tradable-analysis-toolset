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
  def home
    @title = HOME_TITLE
    set_appname
    if current_user != nil
      @analyzers = analyzers_from_session
    end
    @motd = MOTD.new
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

  private ###  Implementation

  pre :mas_session do current_user.mas_session != nil end
  post :result_is_hash do |result| result != nil && result.class == Hash end
  def analyzers_from_session
    mascl = mas_client
    mas_session = current_user.mas_session
    if mas_session.analyzers == nil
      a_list = []
      begin
        mascl.request_analyzers(symbol_list[0])
        a_list = mascl.analyzers
        # Get intraday analyzers, if any.
        mascl.request_analyzers(symbol_list[0],
                                     PeriodTypeConstants::HOURLY)
        a_list << mascl.analyzers
      rescue => e
        if e.to_s !~ /#{MasCommunicationProtocol::INVALID_PERIOD_TYPE}/
          raise e
        end
      end
      mas_session.analyzers = a_list
      mas_session.save
    end
    mas_session.analyzers
  end

end
