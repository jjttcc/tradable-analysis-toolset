#!/usr/bin/env ruby

TATDIR = ENV['TATDIR']
DOMDIR = 'domain'
if TATDIR.nil? then
  raise "Environment variable TATDIR is not set."
end

# Add directories under ./ to LOAD_PATH:
%w{. lib/util config/tat lib/messaging external/data_retrieval
  external/messaging external/utility
}.each do |path|
  $LOAD_PATH << "#{TATDIR}/#{path}"
end

# Add directories under domain/ to LOAD_PATH:
%w{services/managers data_retrieval services/support support
  services/managers/test services/service_coordination services/admin
  services/workers services/workers/test services/reporting facilities
}.each do |path|
  $LOAD_PATH << "#{TATDIR}/#{DOMDIR}/#{path}"
end


require 'application_configuration'
require 'test_eod_retrieval_manager'
require 'admin_tools'
require 'tat_logging'

def user_supplied_symbols
  if ARGV.count > 1 then
    result = ARGV
  else
    result = ['aapl', 'adbe', 'c', 'g', 'fb', 'goog', 'pg', 'true']
  end
end
config = ApplicationConfiguration.new
symbols = user_supplied_symbols
r = TestEODRetrievalManager.new(config, symbols)
r.turn_on_logging
r.verbose = true
r.execute
puts "#{$0} exiting normally"
