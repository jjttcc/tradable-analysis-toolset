
class ErrorLog
  public  ###  Basic operations

  def error(msg)
    $stderr.print :error, ": #{msg}\n"
  end

  def warn(msg)
    $stderr.print :warn, ": #{msg}\n"
  end

  def debug(msg)
    $stderr.print :debug, ": #{msg}\n"
  end

  def info(msg)
    $stderr.print :info, ": #{msg}\n"
  end

end
