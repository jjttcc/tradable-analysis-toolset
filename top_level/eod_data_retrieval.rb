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
  services/service_coordination services/admin services/workers
  services/reporting facilities
}.each do |path|
  $LOAD_PATH << "#{TATDIR}/#{DOMDIR}/#{path}"
end


require 'application_configuration'
require 'eod_retrieval_manager'
require 'admin_tools'
require 'tat_logging'

config = ApplicationConfiguration.new
r = config.service_management.eod_retrieval_manager.new(config)
configure_logging(r)
r.execute
