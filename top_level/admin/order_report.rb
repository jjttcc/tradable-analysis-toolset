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
require 'local_time'
require 'tat_util'

class ReportProcessor
  include Contracts::DSL, LocalTime, TatUtil

  public

  attr_reader :report_callbacks, :report_args, :verbose

  def process_cl_args
    OptionParser.new do |parser|
      parser.on("-o", "--output=filepath",
                "Output report to 'filepath'") do |f|
        @options[:output] = f
        @report_callbacks << self.method(:save_report)
      end
      parser.on("-s", "--start-time=<date/time>",
                "Start report at <date/time>") do |dt|
        stime = parsed_datetime(dt)
        if stime != nil then
          @report_args[:start_time] = stime.to_i.to_s # seconds since "epoch"
        end
      end
      parser.on("-e", "--end-time=<date/time>",
                "End report at <date/time>") do |dt|
        etime = parsed_datetime(dt)
        if etime != nil then
          @report_args[:end_time] = etime.to_i.to_s   # seconds since "epoch"
        end
      end
      parser.on("-k", "--keys=lbl1[,lbl2,...]",
                "restrict report to the specified Keys.") do |k|
        key_args = k.split(/,/)
        if key_args.include?("*") then
          @report_args[:keys] = ['*']
        else
          @report_args[:keys] = key_args.map { |key| key.to_sym }
        end
      end
      parser.on("-c", "--count=<integer>",
                "limit the result Count for each key to 'count'.") do |n|
        if ! is_i?(n) then
          raise "count argument - #{n} - is not an integer."
        end
        @report_args[:count] = n.to_i
      end
    end.parse!
    post_process_args
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
    @report_args = {
      client_methods: @report_callbacks
    }
    @verbose = verbose
  end

  ##### Implementation - utilities

  # DateTime produced by parsing String 's'
  def parsed_datetime(s)
    local_time_from_s(s)
  rescue StandardError => e
    $stderr.puts "Invalid date specified: '#{s}'"
    return nil
  end

  def post_process_args
    if @report_args[:start_time] != nil && @report_args[:end_time].nil?  then
      et = DateTime.now
      @report_args[:end_time] = et.to_i.to_s
    end
  end

end


config = ApplicationConfiguration.new
rproc = ReportProcessor.new(config, program_name)
rproc.process_cl_args
args_hash = rproc.report_args
log = config.message_log
r = config.service_management.reporting_administrator.new(config, log)
if ! args_hash.has_key?(:keys) then
  args_hash[:keys] = r.all_service_keys
end
r.order_reports(args_hash)
report = r.report
