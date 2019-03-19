
class ErrorLog
  include Contracts::DSL

  public  ###  Basic operations

  def error(msg)
    send(:error, msg)
  end

  def warn(msg)
    send(:warn, msg)
  end

  def debug(msg)
    send(:debug, msg)
  end

  def info(msg)
    send(:info, msg)
  end

  protected

  pre :args_exist do |msg, tag| ! (msg.nil? || tag.nil?) end
  def send(tag, msg)
    $stderr.print tag, ": #{msg}\n"
  end

end
