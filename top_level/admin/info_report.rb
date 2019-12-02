#!/usr/bin/env ruby
# "Information" report

if not (ARGV.include?('-q') || ARGV.include?('--quick')) then
  require "action_view"   # Do the wasteful load for fancy output.
end
require 'optparse'
require 'ruby_contracts'
require_relative 'report_setup'

program_name = 'info_report'

require 'application_configuration'
require 'local_time'

class ReportProcessor
  if ARGV.include?('-q') || ARGV.include?('--quick') then
    include Contracts::DSL, LocalTime
  else
    include Contracts::DSL, LocalTime, ActionView::Helpers
  end

  public

  attr_reader :report_callbacks, :report_args, :verbose, :debug,
    :total_only, :counts_only, :quick

  def process_cl_args
    OptionParser.new do |options|
      options.banner = "Display a count for each reporting key"
      options.on("-v", "--verbose",
                "Display all report keys/values") do
        @verbose = true
      end
      options.on("-d", "--debug",
                "Dump/debug data") do
        @debug = true
      end
      options.on("-t", "--total",
                "Display only the total count") do
        @total_only = true
      end
      options.on("-c", "--count",
                "Display only the report-category counts") do
        @counts_only = true
      end
      options.on("-q", "--quick", "Skip formatting - for speed") do
        @quick = true
      end
    end.parse!
  end

  def receive_report(report)
    expected_subkeys = [:count, :first_entry, :last_entry]
    indent = ' ' * 2
    info = "\n"
    total_count = 0
    report.keys.each do |key|
      total_count += report[key][:count]
      if total_only then
        info = ""
      else
        info += "#{key}:\n"
        if verbose then
          subkeys = report[key].keys
        elsif counts_only then
          subkeys = [:count]
        else
          subkeys = expected_subkeys
        end
        subkeys.each do |sk|
          value = report[key][sk].to_s
          if verbose then
            limit = value.length
          else
            limit = STR_SIZE_LIMIT
          end
          info += "#{indent}#{sk}: #{value[0..limit]}"
          if value.length > limit then
            info += "..."
          end
          info += "\n"
        end
      end
    end
    info = "total count: #{formatted_number(total_count)}#{info}"
    puts info
    if debug then
      puts "report: #{report.inspect}"
    end
  end

  private

  STR_SIZE_LIMIT = 244

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

  #####  Implementation

  # 'n' - formatted (e.g., with commas), unless 'quick'
  def formatted_number(n)
    if quick then
      n.to_s
    else
      number_with_delimiter(n)
    end
  end

end

config = ApplicationConfiguration.new
rproc = ReportProcessor.new(config, program_name)
rproc.process_cl_args
args_hash = rproc.report_args
log = config.message_log
r = config.service_management.reporting_administrator.new(config, log)
args_hash[:keys] = r.all_service_keys
r.info(args_hash)
report = r.report
