
desc 'EOD/exchanges-monitoring worker task'
task eod_exchange_monitoring: :environment do
  require 'admin_tools'
  require 'tat_logging'
  config = ApplicationConfiguration.new
  r = config.service_management.exchange_schedule_monitor.new(config)
  configure_logging(r)
puts "[eod_exchange_monitoring] r: #{r.inspect}"
  r.execute
end
