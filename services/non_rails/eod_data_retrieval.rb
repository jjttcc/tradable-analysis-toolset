#!/usr/bin/env ruby

TATDIR = ENV['TATDIR']
SVCDIR = 'services'
if TATDIR.nil? then
  raise "Environment variable TATDIR is not set."
end
puts TATDIR

%w{. lib/util/ lib/config lib/data_retrieval/implementation
lib/data_retrieval/implementation lib/data_retrieval/interface
lib/data_retrieval/interface lib/managers}.each do |path|
  $LOAD_PATH << "#{TATDIR}/#{SVCDIR}/#{path}"
end

require 'eod_retrieval_manager'

r = EODRetrievalManager.new
puts "r: #{r}"
r.execute
