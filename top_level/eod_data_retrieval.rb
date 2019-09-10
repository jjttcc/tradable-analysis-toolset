#!/usr/bin/env ruby

TATDIR = ENV['TATDIR']
#!!!!remove: SVCDIR = 'services'
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
  services/service_coordination
}.each do |path|
  $LOAD_PATH << "#{TATDIR}/#{DOMDIR}/#{path}"
end


require 'eod_retrieval_manager'
require 'application_configuration'

config = ApplicationConfiguration.new
r = config.service_management.eod_retrieval_manager.new(config)
r.execute
