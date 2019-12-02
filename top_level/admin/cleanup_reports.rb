#!/usr/bin/env ruby
# Cleanup user-specified reports.

require 'optparse'
require 'ruby_contracts'

program_name = 'cleanup_reports'
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

  attr_reader :count

  def process_cl_args
    OptionParser.new do |parser|
      parser.on("-c", "--count=count",
                "Count of entries to leave untrimmed") do |c|
        @count = c
      end
    end.parse!
  end

  private

  attr_reader :config, :name

  pre :config do |cfg| cfg != nil end
  def initialize(cfg, name = nil)
    @config = cfg
    @name = name
  end

end

config = ApplicationConfiguration.new
rproc = ReportProcessor.new(config, program_name)
rproc.process_cl_args
log = config.message_log
r = config.service_management.reporting_administrator.new(config, log)
r.cleanup_reports(keys: r.all_service_keys, count: rproc.count)
