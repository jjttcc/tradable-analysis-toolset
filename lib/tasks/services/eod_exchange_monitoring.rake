
desc 'EOD/exchanges-monitoring worker task'
task eod_exchange_monitoring: :environment do
  r = ExchangeScheduleMonitor.new
puts "[eod_exchange_monitoring] r: #{r.inspect}"
  r.execute_eod_monitoring
end
