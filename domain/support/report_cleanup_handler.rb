require 'report_request_handler'

class ReportCleanupHandler < ReportRequestHandler

  public

  def execute(log)
    config.log_reader.trim_contents(report_specs)
  end

end
