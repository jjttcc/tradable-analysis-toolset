
desc 'Start the EODEventManager.'
task manage_event_triggering: :environment do
  if $log.nil? then puts "THERE IS NO log" else puts "log: #{$log}" end
#!!!  manager = EODEventManager.new(ApplicationConfiguration.new, $log)
  config = ApplicationConfiguration.new
  manager = config.service_management.eod_event_manager.new(config)
puts "[manage_event_triggering] manager: #{manager.inspect}"
  manager.execute
end
