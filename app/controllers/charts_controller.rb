require 'yahoo-finance'

class ChartsController < ApplicationController
  include ControllerFacilities
  include Contracts::DSL

  helper_method :period_type_spec_for

  before_action :authenticate
  before_action :validate_params

  pre :user do current_user != nil end
  post :js_data_valid do implies(flash[:error].nil?, gon.data != nil) end
  post :attrs_set do implies(flash[:error].nil?,
                             @symbol == params[:symbol] && @name != nil) end
  post :ptype_set do @period_type != nil end
  def index
    @symbol = params[:symbol]
    @period_type = params[:period_type]
    if @period_type.nil?
      @period_type = PeriodTypeConstants::DAILY
    end
    begin
      ptype_spec = updated_period_type_spec(@period_type)
      start_date, end_date = nil, nil
      if ptype_spec != nil
        start_date = ptype_spec.effective_start_date
        end_date = ptype_spec.effective_end_date
      end
      do_mas_request do
        mas_client.request_tradable_data(@symbol, @period_type,
                                         start_date, end_date)
        mas_client.communication_failed
      end
      if not mas_client.communication_failed then
        @name = tradable_name(@symbol)
      end
    rescue Exception => e
      register_exception(e)
    end
    handle_mas_client_error
    if no_error then
      gon.push({ symbol: @symbol, name: @name,
                 data: mas_client.tradable_data, period_type: @period_type, })
    end
  end

  def update
    raise params.inspect
  end

  public ###  Access

  # The charting (long-term) PeriodTypeSpec, from 'current_user', for
  # 'period_type'
  type :in => String
  pre :signed_in do signed_in? end
  pre :valid_ptype do |ptype|
    PeriodTypeConstants::valid_period_type_name(ptype) end
  post :result_if_spec_match do |result, ptype|
    implies(current_user.charting_specs.find {|s| s.period_type_name == ptype},
            result != nil)
  end
  def period_type_spec_for(period_type)
    result = nil
    specs = current_user.charting_specs
    if specs != nil
      result = specs.find { |s| s.period_type_name == period_type }
    end
    result
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

  # The current_user's PeriodTypeSpec for 'period_type', updated according
  # to the date values in 'params'
  # Example of expected params date format:
  # "startdate"=>{"year"=>"2013", "month"=>"1", "day"=>"6"},
  # "enddate"=>{"year"=>"2017", "month"=>"7", "day"=>"1"}
  def updated_period_type_spec(period_type)
    result = period_type_spec_for(period_type)
    if result.nil?  # No spec for 'period_type' - make one.
      now = DateTime.now
      result = current_user.period_type_specs.create!(
        period_type_id: PeriodTypeConstants.id_for(period_type),
        start_date: DateTime.new((now.year) - 1, now.month, now.day),
        end_date: nil,
        category: PeriodTypeSpec::LONG_TERM
      )
    elsif period_type != current_user.mas_session.last_period_type
      current_user.mas_session.last_period_type = @period_type
      current_user.mas_session.save
      return result   # Dates should not be updated if period_type changed.
    end
    start_date_hash = params['startdate']
    if start_date_hash.nil?
      return result   # No dates present in 'params' at this point.
    end
    end_date_hash = params['enddate']
    new_end_date_blank = false
    orig_start_date, orig_end_date = result.effective_start_date,
      result.effective_end_date
    # (start_date_changed := orig_start_date != start_date_hash)
    start_date_changed = [orig_start_date.year.to_s,
        orig_start_date.month.to_s, orig_start_date.day.to_s] !=
        [start_date_hash['year'], start_date_hash['month'],
        start_date_hash['day']]
    end_date_changed = has_end_date_changed?(orig_end_date, end_date_hash)
    if start_date_changed
$log.debug("sd hash: #{start_date_hash.inspect}") #!!!!!!
      result.start_date = Date.new(start_date_hash['year'].to_i,
             start_date_hash['month'].to_i, start_date_hash['day'].to_i)
    end
    if end_date_changed
      if new_end_date_blank
        result.end_date = nil
      else
        result.end_date = Date.new(end_date_hash['year'].to_i,
               end_date_hash['month'].to_i, end_date_hash['day'].to_i)
      end
    end
    if start_date_changed or end_date_changed
      if ! result.save
        raise "Database update of period type failed [#{result.inspect}]"
      end
    end
    result
  end

  def has_end_date_changed?(orig_date, new_date_hash)
    if (1..2).include?(new_date_hash.values.count { |v| v.blank? })
      # Some, but not all, of new_date_hash.values are blank - thus it is
      # invalid and cannot be used.
      result = false
    elsif orig_date == nil
      # (result = "none of new_date_hash.values is blank")
      result = (new_date_hash.values.detect {|v| v.blank? }) == nil
    else
      result = [orig_date.year.to_s,
        orig_date.month.to_s, orig_date.day.to_s] !=
        [new_date_hash['year'], new_date_hash['month'],
         new_date_hash['day']]
      new_end_date_blank = new_date_hash['year'].blank?
    end
    result
  end

  def tradable_name(symbol)
    # Look first in the database reference table
    t = Tradable.find_by_symbol(symbol)
    if t.nil? then
      # Record for 'symbol' is not yet in the table - look for it.
      begin
        name = $external_tradable_info.name_for(symbol)
        Tradable.create(name: name, symbol: symbol)
      rescue => e
        $log.debug("[#{__FILE__},#{__LINE__}] TradableTools.new or " +
                   "name_for failed [#{e}]")
        name = ""
      end
    else
      name = t.name
    end
    name
  end

end
