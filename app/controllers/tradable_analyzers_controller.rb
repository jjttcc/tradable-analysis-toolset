
class TradableAnalyzersController < ApplicationController
  include Contracts::DSL, ControllerFacilities

  pre :session_exists do current_user.mas_session != nil end
  pre :analyzers_exist do current_user.mas_session.analyzers != nil end
  post :events_type do @analysis_events.class == Hash end
  def index
    chosen_analayzers = params[:analyzers]
    symbols = params[:symbols]
    @analysis_events = {}
    if chosen_analayzers.nil? or symbols.nil? then
      flash[:error] = 'No ' + ((symbols == nil)? 'symbols': 'analyzers') +
        ' were selected for analysis.'
      redirect_to root_path
    else
      begin
        @title = 'Analysis results'
        analyzer_tbl = current_user.mas_session.analyzers
        analyzers = chosen_analayzers.map do |aname|
          analyzer_tbl[aname]
        end
        sdate = params[:startdate]; edate = params[:enddate]
        startdate = Date.new(sdate[:year].to_i, sdate[:month].to_i,
                             sdate[:day].to_i)
        enddate = Date.new(edate[:year].to_i, edate[:month].to_i,
                           edate[:day].to_i)
        do_mas_request do
          @analysis_events = {}
          symbols.each do |symbol|
            mas_client.request_analysis(analyzers, symbol, startdate, enddate)
            @analysis_events[symbol] = mas_client.analysis_data
          end
          mas_client.communication_failed
        end
      rescue => e
        flash[:error] = e.to_s
      end
      handle_mas_client_error
    end
  end

end
