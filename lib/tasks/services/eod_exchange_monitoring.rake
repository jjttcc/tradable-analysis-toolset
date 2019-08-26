
desc 'EOD/exchanges-monitoring worker task'
task eod_exchange_monitoring: :environment do
#!!!  r = ExchangeScheduleMonitor.new(ApplicationConfiguration.new)
  config = ApplicationConfiguration.new
  r = config.service_management.exchange_schedule_monitor.new(config)
puts "[eod_exchange_monitoring] r: #{r.inspect}"
  r.execute_eod_monitoring
end
