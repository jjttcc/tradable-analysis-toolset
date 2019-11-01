#!/usr/bin/env ruby
# Order user-specified reports.

require 'optparse'
require 'ruby_contracts'

program_name = 'order_report'
TATDIR = ENV['TATDIR']
DOMDIR = 'domain'
if TATDIR.nil? then
  raise "Environment variable TATDIR is not set."
end
# Add directories under ./ to LOAD_PATH:
%w{. lib/util config/tat lib/messaging external/data_retrieval
  external/messaging app/model_facilities external/utility
}.each do |path|
  $LOAD_PATH << "#{TATDIR}/#{path}"
end

# Add directories under domain/ to LOAD_PATH:
%w{services/managers data_retrieval services/support support
  services/service_coordination services/admin facilities
}.each do |path|
  $LOAD_PATH << "#{TATDIR}/#{DOMDIR}/#{path}"
end

require 'application_configuration'

class ReportProcessor
  include Contracts::DSL

  public

  attr_reader :report_callbacks, :verbose

  def process_cl_args
    OptionParser.new do |parser|
      parser.on("-o", "--output=filepath",
                "output report to 'filepath'") do |f|
        @options[:output] = f
        @report_callbacks << self.method(:save_report)
      end
    end.parse!
  end

  def receive_report(report)
    if verbose then
      puts "report type: #{report.class}"
      puts "report contents size: #{report.topic_reports.size}"
      puts "report timestamp: #{report.timestamp}"
      puts "labels: #{report.labels}"
      report.labels.each do |l|
        r = report.report_for(l)
        print "report at #{l}: #{r} [#{r.class}]: "
        if r.empty? then
          print "empty\n"
        else
          print "start-time: #{r.start_date_time}, " +
            "end-time: #{r.end_date_time}\n"
        end
        puts "count for #{l}: #{r.count}"
      end
    end
  end

  def save_report(r)
    filepath = @options[:output]
    if filepath != nil then
      serializer = config.serializer.new(r)
      file = File.new(filepath, "w")
      file.write(serializer)
      file.close
    end
  rescue StandardError => e
    msg = "Error opening file '#{filepath}': #{e}"
    if name != nil then
      msg = "#{name}: #{msg}"
    end
    config.error_log.error(msg)
  end

  private

  attr_reader :config, :name

  pre :config do |cfg| cfg != nil end
  def initialize(cfg, name = nil, verbose = false)
    @config = cfg
    @name = name
    @options = {}
    @report_callbacks = [self.method(:receive_report)]
    @verbose = verbose
  end

end


config = ApplicationConfiguration.new
rproc = ReportProcessor.new(config, program_name)
rproc.process_cl_args
log = config.message_log
r = config.service_management.reporting_administrator.new(config, log)
r.order_reports(r.all_service_keys, rproc.report_callbacks)
report = r.report
