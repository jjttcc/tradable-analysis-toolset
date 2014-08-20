require 'ruby_contracts'
require 'yahoo_finance'

class ChartsController < ApplicationController
  include Contracts::DSL

  before_filter :authenticate
  before_filter :validate_params

  pre :user do current_user != nil end
  post :js_data_valid do implies(@error.nil?, gon.data != nil) end
  post :attrs_set do implies(@error.nil?,
                             @symbol == params[:symbol] && @name != nil) end
  post :ptype_set do @period_type != nil end
  def index
#!!!!!REMINDER: symbols and period_types should be stored in the mas_session
#!!!!!so that they don't have to be retrieved from the MAS server each time.
#!!!!!(See charts/index.html.erb)
    @mas_client = mas_client(current_user)
    @error = nil
    @symbol = params[:symbol]
    @period_type = params[:period_type]
    if @period_type.nil?
      @period_type = PeriodTypeConstants::DAILY
    end
    begin
      @mas_client.request_tradable_data(@symbol, @period_type)
      begin
        @name = YahooFinance.quotes([@symbol], [:name])[0].name
        @name.delete!('"')
      rescue
        @name = ""
      end
    rescue => e   # (Likely cause - invalid symbol)
      @error = e.to_s
      flash[:error] = e.to_s
      redirect_to root_path
    end
    gon.push({
      symbol: @symbol,
      name: @name,
      data: @mas_client.tradable_data,
      period_type: @period_type,
# Might want to get rid of this error line - i.e., only invoke
# chars.js.coffee if no errors occurred:
      error: @error,
    })
  end

  def update
    raise params.inspect
  end

  private

  def authenticate
    if current_user.nil?
      deny_access
    else
      super
    end
  end

  def validate_params
    if params.nil? || params[:symbol].nil?
      redirect_back_or_to root_path
    end
  end

end
