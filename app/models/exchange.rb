=begin
 name              | character varying           | not null
 type              | integer                     | not null default 1
 timezone          | character varying           | not null
 full_name         | character varying
=end

# !!!!!!TO-DO[2019-september-iteration]: Move this to the appropriate place:
module TimeUtil

  def self.current_date_time
    DateTime.current
  end

end

class Exchange < ApplicationRecord
  include Contracts::DSL, TatUtil, TAT::Exchange

  public  ###  Access

  has_many   :close_date_links, as: :market
  has_many   :market_close_dates, through: :close_date_links
  has_many   :market_schedules, as: :market

  public  ###  Access

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

  # A list of all components of 'self' (i.e.: self, market_schedules,
  # market_close_dates) that have an updated_at time later than 'datetime'
  post :result_exists do |result| result != nil end
  def updated_components(datetime)
    result = []
    if updated_at > datetime then
      result << self
    end
    market_schedules.each do |s|
      if s.updated_at > datetime then
        result << s
      end
    end
    market_close_dates.each do |mcd|
      if mcd.updated_at > datetime then
        result << mcd
      end
    end
    result
  end

  public  ###  Status report

  def is_market_close_date?
    if current_local_time.nil? then
      update_current_local_time
    end
    year, month, day = current_local_time.year.to_i,
      current_local_time.month.to_i, current_local_time.day.to_i
    closed_today = MarketCloseDate::close_date_for_exchange_id(
      year, month, day, id)
    ! closed_today.empty?
  end

  public  ###  Basic operations

  def reload
    super
    self.current_local_time = nil
    cached_current_schedule = nil
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
