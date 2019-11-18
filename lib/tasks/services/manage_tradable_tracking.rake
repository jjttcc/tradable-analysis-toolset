desc 'Start the TradableTrackingManager.'
task manage_tradable_tracking: :environment do
  require 'admin_tools'
  require 'tat_logging'
  config = ApplicationConfiguration.new
  tracker = config.service_management.tradable_tracker.new(config)
  configure_logging(tracker)
puts "[manage_tradable_tracking] tracker: #{tracker.inspect}"
puts "(Is LOGGING on? - #{tracker.logging_on})"
  tracker.execute
end
