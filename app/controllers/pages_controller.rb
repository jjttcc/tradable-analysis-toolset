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
    if current_user != nil then
      @ana_startdate, @ana_enddate = nil, nil
      @analyzers = analyzers_from_session
      current_user.analysis_specs.each do |spec|
        if spec.period_type == PeriodTypeConstants::DAILY then
          @ana_startdate = spec.effective_start_date
          @ana_enddate = spec.effective_end_date
          break
        end
      end
      if @ana_startdate.nil? then
        @ana_startdate = DateTime.now; @ana_startdate -= 14
      end
      if @ana_enddate.nil? then
        @ana_enddate = DateTime.now; @ana_enddate += 1
      end
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
  pre :symbols_exist do ! symbol_list.empty? end
  post :result_is_hash do |result| result != nil && result.class == Hash end
  def analyzers_from_session
    mascl = mas_client
    mas_session = current_user.mas_session
    if mas_session.analyzers == nil then
      a_list = []
      begin
        symbol = symbol_list[0]
        mascl.request_analyzers(symbol)
        a_list = mascl.analyzers
        # Get intraday analyzers, if any.
        mascl.request_analyzers(symbol, PeriodTypeConstants::HOURLY)
        a_list.push(*mascl.analyzers)
      rescue => e
        if e.to_s !~ /#{MasCommunicationProtocol::INVALID_PERIOD_TYPE}/ then
          flash[:danger] = e.to_s
          redirect_to root_url
        end
      end
      mas_session.analyzers = a_list
      mas_session.save
    end
    mas_session.analyzers
  end

end
