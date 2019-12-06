# Environment set-up for report functionality

TATDIR = ENV['TATDIR']
DOMDIR = 'domain'
if TATDIR.nil? then
  raise "Environment variable TATDIR is not set."
end
# Add directories under ./ to LOAD_PATH:
%w{. lib/util config/tat lib/messaging external/data_retrieval
  external/messaging app/model_facilities external/utility
}.each do |path|
  $LOAD_PATH << "#{TATDIR}/#{path}"
end

# Add directories under domain/ to LOAD_PATH:
%w{services/managers data_retrieval services/support support facilities
  services/service_coordination services/admin services/reporting
}.each do |path|
  $LOAD_PATH << "#{TATDIR}/#{DOMDIR}/#{path}"
end

