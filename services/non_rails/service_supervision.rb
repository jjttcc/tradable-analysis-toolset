#!/usr/bin/env ruby

TATDIR = ENV['TATDIR']
SVCDIR = 'services'
if TATDIR.nil? then
  raise "Environment variable TATDIR is not set."
end

%w{. lib/util/ lib/config lib/data_retrieval/implementation
lib/data_retrieval/implementation lib/data_retrieval/interface
lib/data_retrieval/interface lib/managers/general
lib/managers/service_specific lib/architectural/active_record
lib/architectural/redis lib/support}.each do |path|
  $LOAD_PATH << "#{TATDIR}/#{SVCDIR}/#{path}"
end

require 'ruby_contracts'
require 'services_supervisor'

r = ServicesSupervisor.new

