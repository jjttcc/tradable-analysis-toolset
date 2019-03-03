
desc 'Start the TradableTrackingManager.'
task manage_tradable_tracking: :environment do
  tracker = TradableTrackingManager.new
puts "[manage_tradable_tracking] tracker: #{tracker.inspect}"
  tracker.execute
end
