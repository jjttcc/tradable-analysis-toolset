#!/usr/bin/env ruby
# Test of ReportSpecification

TATDIR = ENV['TATDIR']
VERBOSE = ENV.has_key?('TESTVERBOSE')
DOMDIR = 'domain'
if TATDIR.nil? then
  raise "Environment variable TATDIR is not set."
end

# Add directories under domain/ to LOAD_PATH:
%w{services/managers data_retrieval services/support support
  services/service_coordination services/reporting
}.each do |path|
  $LOAD_PATH << "#{TATDIR}/#{DOMDIR}/#{path}"
end

require 'report_specification'
require 'tat_util'

include TatUtil

repkey = :rk
keys = [:key1, :key2]
type = ReportSpecification::CREATE_TYPE
if VERBOSE then puts "type: #{type}" end
spec0 = ReportSpecification.new(type: type, response_key: :mykey,
                                key_list: :yourkey)
check(spec0[:key_list].is_a?(Array))
spec1 = ReportSpecification.new(type: type, response_key: repkey,
                                key_list: keys)
if VERBOSE then puts "s1tojson: #{spec1.to_json}" end
spec2 = ReportSpecification.new(spec1.to_json)
spec3 = ReportSpecification.new(spec2)
check(spec1[:response_key] == repkey,
      "incorrect response_key (#{spec1[:response_key]})")
check(spec1[:key_list] == keys,
      "incorrect keys (#{spec1[:key_list]})")
check(spec1[:block_msecs] == nil,
      "block_msecs should be nil (#{spec1[:block_msecs]})")
check(spec1[:new_only] == false,
      "new_only should be nil (#{spec1[:new_only]})")
spec1.keys.each do |k|
=begin
  puts "k: #{k}, spec1[k]: #{spec1[k]}, spec2[k]: #{spec2[k]}"
  puts "spec1[k].class: #{spec1[k].class}, spec2[k].class: #{spec2[k].class}"
  puts "spec1[k] == spec2[k]: #{spec1[k] == spec2[k]}"
=end
  check(spec1[k] == spec2[k])
  check(spec3[k] == spec2[k])
end
hargs = {
  :response_key => 'myreportkey',
  :key_list => keys,
  :block_msecs => 555,
  :new_only => true,
  :type => :create,
}
spec4 = ReportSpecification.new(hargs)
hargs.keys.each do |k|
  check(spec4.has_key?(k), "spec4.has_key?(#{k}) failed")
  check(spec4[k].to_s == hargs[k].to_s, "#{spec4[k]} != #{hargs[k]}")
end
spec4.keys.each do |k|
  check(spec4[k].to_s == hargs[k].to_s, "#{spec4[k]} != #{hargs[k]}")
end
hargs[:new_only] = false
check(spec4[:new_only] != hargs[:new_only])
spec5 = ReportSpecification.new(spec4.to_str)
check(spec5[:response_key] == spec4[:response_key], "same response_key")
puts "Test complete."
