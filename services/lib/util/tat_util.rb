# Utility functionality for the TAT application
module TatUtil

  public  ###  Access

  # 'datetime' in the specified 'timezone' - If not provided, 'datetime'
  # defaults to DateTime.current, resulting in the current time in the
  # specified timezone.
  # For example: If the rails system time (which in this application is UTC)
  # is 2019-02-13, 5:00 pm, the result for the NYSE (America/New_York)
  # will be 2019-02-13, 12:00 pm.
  def local_time(timezone, datetime = DateTime.current)
    result = datetime.in_time_zone(timezone)
#puts "lt: datetime, result: #{datetime}, #{result}"
    result
  end

  public  ###  Basic operations

  # Assert the 'boolean_expression' is true - raise 'msg' if it is false.
  def check(boolean_expression, msg = nil)
    if msg.nil? then
      msg = "false assertion: '#{caller_locations(1, 1)[0].label}'"
    end
    if ! boolean_expression then
      raise msg
    end
  end

end
