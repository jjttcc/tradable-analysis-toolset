#!/usr/bin/env ruby
# Script providing report-analysis services

require 'ruby_contracts'

program_name = 'report_analysis'
#!!!!Consider requiring some of this setup stuff from another file.
TATDIR = ENV['TATDIR']
DOMDIR = 'domain'
if TATDIR.nil? then
  raise "Environment variable TATDIR is not set."
end
# Add directories under ./ to LOAD_PATH:
%w{. lib/util config/tat lib/messaging external/data_retrieval
  external/messaging app/model_facilities external/utility
  top_level/admin
}.each do |path|
  $LOAD_PATH << "#{TATDIR}/#{path}"
end

# Add directories under domain/ to LOAD_PATH:
%w{services/managers data_retrieval services/support support facilities
  services/service_coordination services/admin services/reporting
}.each do |path|
  $LOAD_PATH << "#{TATDIR}/#{DOMDIR}/#{path}"
end

require 'application_configuration'
require 'report_argv_processor'
require 'report_tools'
require 'report_analysis_prompt'
require 'time_util'
require 'local_time'

config = ApplicationConfiguration.new
options = ReportArgvProcessor.new(config, program_name)
infile = options.input_file
prompt = ReportAnalysisPrompt.new(infile, config)
prompt.start_status
