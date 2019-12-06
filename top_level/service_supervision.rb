#!/usr/bin/env ruby

TATDIR = ENV['TATDIR']
SVCDIR = 'services'
if TATDIR.nil? then
  raise "Environment variable TATDIR is not set."
end

# Add directories under ./ to LOAD_PATH:
%w{. lib/util config/tat lib/messaging external/data_retrieval
  external/messaging external/utility domain/data_retrieval
  domain/services/support domain/services/admin domain/services/reporting
  domain/support domain/facilities
}.each do |path|
  $LOAD_PATH << "#{TATDIR}/#{path}"
end

# Add directories under services/ to LOAD_PATH:
%w{. managers services/non_rails/managers/service_specific
services/non_rails/top_level}.each do |path|
  $LOAD_PATH << "#{TATDIR}/#{SVCDIR}/#{path}"
end

require 'ruby_contracts'
require 'services_supervisor'
require 'application_configuration'
require 'admin_tools'
require 'tat_logging'

r = ServicesSupervisor.new(ApplicationConfiguration.new)
configure_logging(r)
