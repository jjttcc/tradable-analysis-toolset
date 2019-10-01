desc 'Start the TradableTrackingManager.'
task manage_tradable_tracking: :environment do
#!!!  tracker = TradableTrackingManager.new(ApplicationConfiguration.new)
  config = ApplicationConfiguration.new
  tracker = config.service_management.tradable_tracker.new(config)
  if ENV['TAT_LOGGING'] or ENV['TAT_TRACKING'] then
    tracker.turn_on_logging
puts "logging is on for the tracker [#{tracker.inspect}]"
  end
puts "[manage_tradable_tracking] tracker: #{tracker.inspect}"
puts "(Is logging on? - #{tracker.logging_on})"
  tracker.execute
end
