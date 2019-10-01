# Exchanges for tradables (such as a stock-market exchange - e.g.: NYSE)
module TAT
  module Exchange
    include Persistent, Contracts::DSL, TatUtil, TimeUtilities

    public

    #####  Access

    STOCK, ECN, COMMODITY, CURRENCY = "stock", "ecn", "commodity", "currency"

    def fields
      [:name, :type, :timezone, :full_name]
    end

    def associations
      [:market_close_dates, :market_schedules]
    end

    # A list of all components of 'self' (i.e.: self, market_schedules,
    # market_close_dates) that have an "updated-at" time later than 'datetime'
    post :result_exists do |result| result != nil end
    def updated_components(datetime)
      raise "Fatal: abstract method: #{self.class} #{__method__}"
    end

    # The MarketSchedule for today (in zone 'timezone')
    post :current_time_set do ! current_local_time.nil? end
    post :cached_schedule_set do ! cached_current_schedule.nil? end
    def schedule_for_today
      if current_local_time.nil? then
        update_current_local_time
      end
      if cached_current_schedule.nil? then
        self.cached_current_schedule = schedule_for_date(current_local_time)
      end
      cached_current_schedule
    end

    # The time at which the exchange closes today
    pre :is_trading_day do is_trading_day? end
    post :valid do |result| result != nil && result.respond_to?(:strftime) end
    post :invariant do invariant end
    def closing_time
      schedule = schedule_for_today
      _, result = schedule.core_hours(current_local_time)
      result
    end

    #####  Boolean queries

    # Will 'self' (this exchange) be open for trading today?
    post :invariant do invariant end
    def is_trading_day?
      schedule = schedule_for_today
      ! is_market_close_date? &&
        schedule.is_trading_day?(current_local_time.wday)
    end

    # Is today a "market-closed" date (where today's date is the date
    # part of 'local_time(timezone)') - i.e., is specified as a close-date by
    # 'market_close_dates'?
    post :current_time_set do current_local_time != nil end
    def is_market_close_date?
      if current_local_time.nil? then
        update_current_local_time
      end
      year, month, day = current_local_time.year.to_i,
        current_local_time.month.to_i, current_local_time.day.to_i
      closed_today_dates = closed_dates(year, month, day)
      closed_today_dates.count > 0
    end

    # Is the exchange open - i.e., is today a trading day for the exchange
    # ('is_trading_day?') and is the current time within the exchange's core
    # trading hours (ignoring possible break periods, such as for lunch)?
    post :invariant do invariant end
    def is_open?
      result = false
      if ! is_market_close_date? then
        schedule = schedule_for_today
        if schedule.is_trading_day?(current_local_time.wday) then
          result = schedule.in_core_hours?(current_local_time)
        end
      end
      result
    end

    #####  State-changing operations

    # Update 'current_local_time' to the current time in zone 'timezone'.
    post :current_time_set do ! current_local_time.nil? end
    post :nil_schedule do cached_current_schedule.nil? end
    def update_current_local_time
      self.current_local_time = local_time(timezone)
      self.cached_current_schedule = nil
    end

    # The MarketSchedule for 'self' for the specified date (in self's
    # local time)
    # nil if the date is not in the database - e.g., a far-future date
    # If 'date' is not provided, DateTime.current is used.
    pre :date_type do |date| date != nil && date.respond_to?(:strftime) end
    post :nil_date_iff_non_holiday do |res|
      implies(res != nil, res.date.nil? == ! res.holiday?) end
    post :is_market_schedule do |res|
      implies(res != nil, res.is_a?(TAT::MarketSchedule)) end
    def schedule_for_date(date = current_date_time)
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

    ##### Class invariant

    def invariant
      super &&
        implies(current_local_time != nil,
                current_local_time.respond_to?(:wday)) &&
        implies(type != nil, [STOCK, ECN, COMMODITY, CURRENCY].include?(type))
    end

    protected

    attr_accessor :current_local_time, :cached_current_schedule

    ##### Hook methods

    # Query: Date[s] for which this exchange is closed on the specified day
    post :exists do |result| result != nil end
    def closed_dates(year, month, day)
      raise "Fatal: abstract method: #{self.class} #{__method__}"
    end

  end
end
