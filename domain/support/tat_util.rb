# Utility functionality for the TAT application
module TatUtil
  include Contracts::DSL

  public

  #####  Basic operations

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
