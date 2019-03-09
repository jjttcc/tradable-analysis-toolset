=begin
 schedule_type          | integer                     | not null default 1
 date                   | character varying
 pre_market_start_time  | character varying
 pre_market_end_time    | character varying
 post_market_start_time | character varying
 post_market_end_time   | character varying
 core_start_time        | character varying           | not null
 core_end_time          | character varying           | not null
=end

# Time schedules (i.e., pre-market hours, core hours, post-market hours)
# for a market/exchange
# Note: A null 'date' signifies the regular schedule (i.e., as opposed to
# an "exceptional" (holiday) schedule, such as the day after Thanksgiving
# in the US).
class MarketSchedule < ApplicationRecord
  include Contracts::DSL, TatUtil

  public

  belongs_to :market, polymorphic: true

  enum schedule_type: {
    mon_fri:        1, # Monday through Friday
    seven_day:      2, # all 7 days a week
    sun_thu:        3, # Sunday through Thursday
    sat_wed:        4, # Saturday through Wednesday
    holiday:        5, # on or near holiday (probably with shortened hours)
  }

  public  ###  Access

  # Is the specified date/time a trading day according to self's schedule?
  # (Note: This logic ignores special "closed" dates, such as holidays,
  # since this model does not know about close dates.  Therefore, to get a
  # complete answer to the question (Is this a trading day?) the
  # MarketCloseDate model also needs to be consulted.)
  def is_trading_day?(localtime)
    day_of_week = localtime.wday  # 0: sunday, 1: monday, ... 6: saturday
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

  # Core start and end times, if is_trading_day?
  post :nil_iff_not_trading_day do |result, localtime|
    ! is_trading_day?(localtime) == result.nil? end
  def core_hours(localtime)
    result = nil
    start_time = localtime.change(hour: core_start_time[0..1].to_i,
                                  min: core_start_time[3..4].to_i)
    end_time = localtime.change(hour: core_end_time[0..1].to_i,
                                  min: core_end_time[3..4].to_i)
    if ! (start_time.nil? || end_time.nil?) then
      result = [start_time, end_time]
    end
    result
  end

  # Is the specified date/time within the core trading hours - i.e., is
  # 'localtime' a trading day and is it >= core_start_time and <=
  # core_end_time?
  post :trading_day do |result, time| implies(result, is_trading_day?(time)) end
  def in_core_hours?(localtime)
    result = false
    if is_trading_day?(localtime) then
      start_time, end_time = core_hours(localtime)
      result = localtime >= start_time && localtime <= end_time
    end
    result
  end

end
