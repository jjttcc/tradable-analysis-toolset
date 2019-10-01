require 'active_support/time'

# Time- and date-related utility functions
module TimeUtil
  include Contracts::DSL

  post :exists do |result| result != nil end
  def self.current_date_time
    DateTime.current
  end

  pre  :tz_good do |tz| ! tz.nil? end
  post :exists do |result| result != nil end
  def self.local_time(timezone, datetime = current_date_time)
    result = datetime.in_time_zone(timezone)
    result
  rescue NoMethodError => err
    # (Cover the case in which 'datetime' does not have an 'in_time_zone'
    # method.)
    return TimeWithZone.new(datetime, datetime.zone).in_time_zone(timezone)
  end

  # A new date-time created by, essentially, cloning 'datetime' and then
  # setting its hour and minute components to 'hour' and 'minute',
  # respectively and its date (ymd) components to those of 'datetime'.
  pre  :args_good do |dt, h, m| ! (dt.nil? || h.nil? || m.nil?) end
  post :result_good do |result| result != nil end
  def self.new_time_from_h_m(datetime, hour, minute)
    datetime.change(hour: hour, minute: minute)
  rescue NoMethodError => err
    # (Cover the case in which 'datetime' does not have a 'change' method.)
    dt = DateTime.new(datetime.year, datetime.month, datetime.day,
                         hour, minute)
    dt.change(hour: hour, minute: minute)
  end

end
