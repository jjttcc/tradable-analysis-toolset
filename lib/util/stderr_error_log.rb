require 'error_log'

# Implementation of ErrorLog using $stderr
class StderrErrorLog
  include ErrorLog

  protected

  def send(tag, msg)
#!!!!to-do: add date/time-stamp to 'tag'
    $stderr.print tag, ": #{msg}\n"
  end

end
