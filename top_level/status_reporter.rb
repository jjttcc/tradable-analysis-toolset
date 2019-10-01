#!/usr/bin/env ruby

TATDIR = ENV['TATDIR']
DOMDIR = 'domain'
if TATDIR.nil? then
  raise "Environment variable TATDIR is not set."
end

# Add directories under ./ to LOAD_PATH:
%w{. lib/util config/tat lib/messaging external/data_retrieval
  external/messaging
}.each do |path|
  $LOAD_PATH << "#{TATDIR}/#{path}"
end

# Add directories under domain/ to LOAD_PATH:
%w{services/managers data_retrieval services/support support
  services/service_coordination facilities
}.each do |path|
  $LOAD_PATH << "#{TATDIR}/#{DOMDIR}/#{path}"
end


require 'status_reporting'
require 'application_configuration'

config = ApplicationConfiguration.new
log = config.message_log
r = config.service_management.status_reporting_manager.new(config)
r.execute
