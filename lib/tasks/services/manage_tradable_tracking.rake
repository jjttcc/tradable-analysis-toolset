desc 'Start the TradableTrackingManager.'
task manage_tradable_tracking: :environment do
#!!!  tracker = TradableTrackingManager.new(ApplicationConfiguration.new)
  config = ApplicationConfiguration.new
  tracker = config.service_management.tradable_tracker.new(config)
puts "[manage_tradable_tracking] tracker: #{tracker.inspect}"
  tracker.execute
end
