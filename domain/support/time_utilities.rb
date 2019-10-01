# Time/date-based utility functionality for the TAT application
# Note: classes that include this module must ensure the invariant by
# setting the 'time_utilities_implementation' attribute.
module TimeUtilities
  include Contracts::DSL

  public

  #####  Access

  pre  :time_util_imp_exists do invariant end
  post :exists do |result| result != nil end
  def current_date_time
    time_utilities_implementation::current_date_time
  end

  # 'datetime' in the specified 'timezone' - If not provided, 'datetime'
  # defaults to DateTime.current, resulting in the current time in the
  # specified timezone.
  # For example: If the rails system time (which in this application is UTC)
  # is 2019-02-13, 5:00 pm, the result for the NYSE (America/New_York)
  # will be 2019-02-13, 12:00 pm.
  pre  :time_util_imp_exists do invariant end
  pre  :tz_good do |tz| ! tz.nil? end
  post :exists do |result| result != nil end
  def local_time(timezone, datetime = current_date_time)
    time_utilities_implementation::local_time(timezone, datetime)
  end

  # A new date-time created by, essentially, cloning 'datetime' and then
  # setting its hour and minute components to 'hour' and 'minute',
  # respectively and its date (ymd) components to those of 'datetime'.
  pre  :args_good do |dt, h, m| ! (dt.nil? || h.nil? || m.nil?) end
  post :result_good do |result| result != nil end
  def new_time_from_h_m(datetime, hour, minute)
    time_utilities_implementation::new_time_from_h_m(datetime, hour, minute)
  end

  #####  Invariant

  # (time_utilities_implementation attribute must be set)
  def invariant
    time_utilities_implementation != nil
  end

  protected

  attr_accessor :time_utilities_implementation

end
