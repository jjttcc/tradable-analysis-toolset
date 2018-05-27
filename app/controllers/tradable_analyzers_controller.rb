
class TradableAnalyzersController < ApplicationController
  include Contracts::DSL, ControllerFacilities

  pre :session_exists do current_user.mas_session != nil end
  pre :analyzers_exist do current_user.mas_session.analyzers != nil end
  post :events_type do @analysis_events.class == Hash end
  def index
    chosen_analayzers = params[:analyzers]
#!!!!period_types = params[:period_types]
    symbols = params[:symbols]
    @analysis_events = {}
    prep_error = false
    if chosen_analayzers.nil? or symbols.nil? then
      flash[:error] = 'No ' + ((symbols == nil)? 'symbols': 'analyzers') +
        ' were selected for analysis.'
      prep_error = true
    else
      begin
        @title = 'Analysis results'
        analyzer_tbl = current_user.mas_session.analyzers
        analyzers = chosen_analayzers.map do |aname|
          analyzer_tbl[aname]
        end
#!!!!!TO-DO: It might be best to change mas_client.request_analysis back
#!!!!!to not take a 'period_types' argument, since the period type can
#!!!!!be obtained from the analyzer.
#!!!!!ON THE OTHER HAND: The period-type might not belong in the
#!!!!!TradableAnalyzer - It might belong with an associated set of parameters.
        period_types = analyzers.map do |a|
          a.period_type
        end
        sdate = params[:startdate]; edate = params[:enddate]
        startdate = Date.new(sdate[:year].to_i, sdate[:month].to_i,
                             sdate[:day].to_i)
        enddate = Date.new(edate[:year].to_i, edate[:month].to_i,
                           edate[:day].to_i)
        do_mas_request do
          @analysis_events = {}
          symbols.each do |symbol|
            mas_client.request_analysis(analyzers, period_types, symbol,
                                        startdate, enddate)
            @analysis_events[symbol] = mas_client.analysis_data
          end
          mas_client.communication_failed
        end
      rescue => e
        flash[:error] = e.to_s
      end
      handle_mas_client_error
    end
    if prep_error then
      redirect_to root_path
    end
  end

end
