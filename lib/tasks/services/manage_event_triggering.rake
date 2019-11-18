
desc 'Start the EODEventManager.'
task manage_event_triggering: :environment do
  require 'admin_tools'
  require 'tat_logging'
  if $log.nil? then puts "THERE IS NO log" else puts "log: #{$log}" end
  config = ApplicationConfiguration.new
  manager = config.service_management.eod_event_manager.new(config)
  configure_logging(manager)
puts "[manage_event_triggering] manager: #{manager.inspect}"
  manager.execute
end
