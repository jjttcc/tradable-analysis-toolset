require 'report_request_handler'

class ReportCreationHandler < ReportRequestHandler

  public

  def execute(log)
    log.set_object(report_specs.response_key, report)
  end

  private

  # Data gathered using specs via 'report_specs'
  pre  :has_key_list do
    report_specs[:key_list] != nil && ! report_specs[:key_list].empty? end
  post :resgood do |result| result != nil && result.is_a?(StatusReport) end
  def report
puts "[RCH] A"
#    contents = config.log_reader.contents_for(report_specs.retrieval_args)
#!!!!try:
contents = config.log_reader.contents_for(report_specs)
puts "[RCH] B"
    result = config.status_report.new(contents)
puts "[RCH] C - report got a #{result}"
puts "[RCH] report's subcounts: #{result.sub_counts}"
    result
  rescue StandardError => e
puts "I found an e: #{e}" #!!!!
puts "Here is our stack:\n#{caller.join("\n")}" #!!!!
    raise e
  end

end
