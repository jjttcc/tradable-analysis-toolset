#!/usr/bin/env ruby

TATDIR = ENV['TATDIR']
SVCDIR = 'services'
if TATDIR.nil? then
  raise "Environment variable TATDIR is not set."
end

# Add directories under ./ to LOAD_PATH:
%w{. lib/util config/non_rails lib/messaging external/data_retrieval
  external/messaging domain/data_retrieval/interface
  domain/data_retrieval/implementation
}.each do |path|
  $LOAD_PATH << "#{TATDIR}/#{path}"
end

# Add directories under services/ to LOAD_PATH:
%w{. managers services/non_rails/managers/service_specific
services/non_rails/top_level support}.each do |path|
  $LOAD_PATH << "#{TATDIR}/#{SVCDIR}/#{path}"
end

require 'ruby_contracts'
require 'services_supervisor'

r = ServicesSupervisor.new

