task_title = 'EOD_MON_SETUP'
if ENV[task_title] then
  require "#{Rails.root}/test/helpers/eod_monitoring_setup"

  desc 'Set up for an EOD-exchange-monitoring test'
  task eod_mon_setup: :environment do
    symbols = ENV[task_title].split(',')
    if symbols.empty? then
      symbols = ['F', 'IBM']
    end
    admin = EODMonitoringSetup.new(symbols)
    admin.execute
  end
end
