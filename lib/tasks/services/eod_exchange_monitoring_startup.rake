
desc 'EOD/exchanges-monitoring worker task'
task eod_exchange_monitoring_startup: :environment do
  r = ExchangeScheduleMonitor.new
puts "[start_eod_exchange_monitoring] r: #{r.inspect}"
  r.execute_eod_monitoring
end
