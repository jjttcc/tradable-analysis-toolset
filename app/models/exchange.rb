=begin
 name              | character varying           | not null
 type              | integer                     | not null default 1
 timezone          | character varying           | not null
 full_name         | character varying
=end


class Exchange < ApplicationRecord
  include Contracts::DSL, TatUtil

  public  ###  Access

  has_many   :close_date_links, as: :market
  has_many   :market_close_dates, through: :close_date_links
  has_many   :market_schedules, as: :market

  attr_reader :current_local_time

  public  ###  Access

  # The MarketSchedule for today (in zone 'timezone')
  post :cached_schedule_set do ! @cached_current_schedule.nil? end
  post :current_time_set do ! @current_local_time.nil? end
  def schedule_for_today
    if @current_local_time.nil? then
      update_current_local_time
    end
    if @cached_current_schedule.nil? then
      @cached_current_schedule = schedule_for_date(@current_local_time)
    end
    @cached_current_schedule
  end

  # The MarketSchedule for 'self' for the specified date (in self's local time)
  # nil if the date is not in the database - e.g., a far-future date
  # If 'date' is not provided, DateTime.current is used.
  pre :date_type do |date| date != nil && date.respond_to?(:strftime) end
  post :nil_iff_non_holiday do |res| res.date.nil? == ! res.holiday? end
  def schedule_for_date(date = DateTime.current)
    result = nil
    localtime = local_time(timezone, date)
    localdate_str = localtime.strftime("%Y-%m-%d")
    # Since today is not a holiday, check for day before or after holiday:
    near_holidays = market_schedules.select do |s|
      # (Note: 'holiday?' actually means bordering a holiday.)
      s.holiday? && s.date == localdate_str
    end
    if ! near_holidays.empty? then
      check(near_holidays.count == 1,
        "invalid data: duplicate market schedules for the same date:" +
          " #{near_holidays.inspect} (for exchange #{self.inspect})")
      result = near_holidays.first
      check(result.holiday? && result.date == localdate_str)
    else  # (near_holidays.empty?)
      regular_days = market_schedules.select do |s|
        s.date == nil
      end
      check(! regular_days.empty?, "invalid data: no regular schedules " +
          "configured for exchange #{self.inspect}")
      check(regular_days.count == 1, "invalid data: duplicate regular " +
          "schedules: #{regular_days.inspect} (for exchange #{self.inspect})")
      result = regular_days.first
    end
    result
  end

  # The time at which the exchange closes today
  pre :is_trading_day do is_trading_day? end
  post :valid do |result| result != nil && result.respond_to?(:strftime) end
  def closing_time
    schedule = schedule_for_today
    _, result = schedule.core_hours(@current_local_time)
    result
  end

  public  ###  Basic operations

  # Update 'current_local_time' to the current time in zone 'timezone'.
  post :current_time_set do ! current_local_time.nil? end
  post :nil_schedule do @cached_current_schedule.nil? end
  def update_current_local_time
    @current_local_time = local_time(timezone)
    @cached_current_schedule = nil
  end

  def reload
    super
    @current_local_time = nil
    @cached_current_schedule = nil
  end

  public  ###  Status report

  # A list of all components of 'self' (i.e.: self, market_schedules,
  # market_close_dates) that have an updated_at time later than 'datetime'
  post :result_exists do |result| result != nil end
  def updated_components(datetime)
    result = []
    if updated_at > datetime then
      result << self
    end
    market_schedules.each do |s|
#!!!new_s = MarketSchedule.find(s.id)
#!!!      if new_s.updated_at > datetime then
      if s.updated_at > datetime then
puts "up_since[2] result #{result} [new updatedat: #{s.updated_at}]"
        result << s
      end
    end
    market_close_dates.each do |mcd|
      if mcd.updated_at > datetime then
        result << mcd
      end
    end
puts "up_since[3] result #{result}" if result.count > 0
    result
  end

  # Was this object updated - where its settings, in the database, changed
  # after 'datetime'?
  def updated_since?(datetime)
#!!!!Call the parent 'reload' method: [needed? probably not]
#!!!!ApplicationRecord.instance_method(:reload).bind(self).call
puts "up_since[0] (since dt: #{datetime})"
    result = updated_at > datetime
puts "up_since[1] result #{result} [updatedat: #{updated_at}"
    if ! result then
      market_schedules.each do |s|
new_s = MarketSchedule.find(s.id)
#!!!!s.reload
puts "up_since[2] result #{result} [new updatedat: #{new_s.updated_at}]"
        if new_s.updated_at > datetime then
          result = true
          break
        end
      end
puts "up_since[3] result #{result}"
      if ! result then
        market_close_dates.each do |mcd|
#!!!!mcd.reload
          if mcd.updated_at > datetime then
            result = true
            break
          end
        end
      end
puts "up_since[3] result #{result}"
    end
    result
  end

  # Is today a "market-closed" date (where today's date is the date
  # part of 'local_time(timezone)') - i.e., is specified as a close-date by
  # 'market_close_dates'?
  post :current_time_set do @current_local_time != nil end
  def is_market_close_date?
    if @current_local_time.nil? then
      update_current_local_time
    end
    year, month, day = @current_local_time.year.to_i,
      @current_local_time.month.to_i, @current_local_time.day.to_i
    closed_today = MarketCloseDate::close_date_for_exchange_id(
      year, month, day, id)
    ! closed_today.empty?
  end

  # Will 'self' (this exchange) be open for trading today?
  def is_trading_day?
    schedule = schedule_for_today
    ! is_market_close_date? && schedule.is_trading_day?(@current_local_time)
  end

  # Is the exchange open - i.e., is today a trading day for the exchange
  # ('is_trading_day?') and is the current time within the exchange's core
  # trading hours (ignoring possible break periods, such as for lunch)?
  def is_open?
    result = false
    if ! is_market_close_date? then
      schedule = schedule_for_today
      if schedule.is_trading_day?(@current_local_time) then
        result = schedule.in_core_hours?(@current_local_time)
      end
    end
puts "Am I #{name} open? - #{result}"
    result
  end

  private

  self.inheritance_column = :sti_not_used

  enum type: {
    stock:          1,
    ecn:            2,
    commodity:      3,
    currency:       4,
    #...
  }

end
