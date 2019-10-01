# Time schedules (i.e., pre-market hours, core hours, post-market hours)
# for a market/exchange
# Note: A null 'date' signifies the regular schedule (i.e., as opposed to
# an "exceptional" (holiday) schedule, such as the day after Thanksgiving
# in the US).
module TAT
  module MarketSchedule
    include Contracts::DSL, Persistent, TatUtil, TimeUtilities

    public

    def fields
      [
        :schedule_type, :date, :pre_market_start_time, :pre_market_end_time,
        :post_market_start_time, :post_market_end_time, :core_start_time,
        :core_end_time
      ]
    end

    def associations
      [:market]
    end

    # mnemonic constants for 'schedule_type':
    MON_FRI, SEVEN_DAY, SUN_THU, SAT_WED, HOLIDAY = 1, 2, 3, 4, 5

    #####  Access

    # Core start and end times, if is_trading_day?
    pre  :good_time do |ltime| ltime != nil && ltime.respond_to?(:wday) end
    post :nil_iff_not_trading_day do |result, ltime|
      ! is_trading_day?(ltime.wday) == result.nil? end
    post :invariant do invariant end
    def core_hours(localtime)
      result = nil
      start_time = new_time_from_h_m(localtime, core_start_time[0..1].to_i,
                                     core_start_time[3..4].to_i)
      end_time = new_time_from_h_m(localtime, core_end_time[0..1].to_i,
                                   core_end_time[3..4].to_i)
      if ! (start_time.nil? || end_time.nil?) then
        result = [start_time, end_time]
      end
      result
    end

    # integer value of 'schedule_type'
    def schedule_type_as_integer
      raise "Fatal: abstract method: #{self.class} #{__method__}"
    end

    #####  Boolean queries

    # Is the specified day-of-the-week (0 -> Sunday, ..., 6 -> Saturday) a
    # trading day according to self's # schedule?
    # (Note: This logic ignores special "closed" dates, such as holidays,
    # since this model does not know about close dates.  Therefore, to get a
    # complete answer to the question (Is this a trading day?) the
    # MarketCloseDate model also needs to be consulted.)
    pre  :good_day do |dw| dw != nil && dw >= 0 && dw <= 6 end
    post :result_exists do |result| result != nil end
    post :invariant do invariant end
    def is_trading_day?(day_of_week)
      result = false
      # Check 'schedule_type' with respect to day_of_week:
      if mon_fri? then
        result = day_of_week.between?(1, 5) # between monday - friday
      elsif sun_thu? then
        result = day_of_week.between?(0, 4) # between sunday - thursday
      elsif sat_wed? then
        result = day_of_week == 6 ||
          day_of_week.between?(0, 3) # between sunday - thursday
      elsif seven_day? || holiday? then
        # (seven_day means "It's always a trading day".)
        # (holiday means a "near-holiday" trading day [such as Friday after
        # Thanksgiving in US].)
        result = true
      else
        raise "Data corruption: invalid 'schedule_type' for #{self}: " +
          schedule_type
      end
      result
    end

    # Is the specified date/time within the core trading hours - i.e., is
    # 'localtime' a trading day and is it >= core_start_time and <=
    # core_end_time?
    pre  :good_time do |ltime| ltime != nil && ltime.respond_to?(:wday) end
    post :trading_day_if_true do |result, ltime|
      implies(result, is_trading_day?(ltime.wday)) end
    post :invariant do invariant end
    def in_core_hours?(localtime)
      result = false
      if is_trading_day?(localtime.wday) then
        start_time, end_time = core_hours(localtime)
        result = localtime >= start_time && localtime <= end_time
      end
      result
    end

    ### Schedule-type queries - auto-constructed abstract methods:
    [
      # Is "self" a Monday-through-Friday schedule?
      'mon_fri?',
      # Is "self" a 7-day (i.e., every day) schedule?
      'seven_day?',
      # Is "self" a Sunday-through-Thursday schedule?
      'sun_thu?',
      # Is "self" a Saturday-through-Wednesday schedule?
      'sat_wed?',
      # Is "self" a schedule for a special "near-holiday"?
      'holiday?'
    ].each do |m_name|
      define_method(m_name) do
        raise "Fatal: abstract method: #{self.class} #{__method__}"
      end
    end

    ##### Class invariant

    def invariant
      super && implies(schedule_type != nil, [MON_FRI, SEVEN_DAY, SUN_THU,
        SAT_WED, HOLIDAY].include?(schedule_type_as_integer))
    end

  end
end
