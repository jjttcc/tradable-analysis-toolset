SYM_VAR = 'TEST_SYMBOLS'

def user_supplied_symbols
  if ENV.has_key?(SYM_VAR) && ENV[SYM_VAR] != nil then
    result = ENV[SYM_VAR].split(",")
  else
    result = ['aapl', 'adbe', 'c', 'g', 'fb', 'goog', 'pg', 'true']
  end
end

desc 'EOD/exchanges-monitoring worker task'
task test_eod_exchange_monitoring: :environment do
  require 'admin_tools'
  require 'tat_logging'
  config = ApplicationConfiguration.new
  symbols = user_supplied_symbols
  r = TestExchangeScheduleMonitor.new(config, symbols)
  configure_logging(r)
  r.execute
end
