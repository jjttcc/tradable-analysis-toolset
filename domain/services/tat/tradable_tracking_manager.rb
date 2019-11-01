# Manager responsible for identifying tradables that are being used and
# marking them as such in the tradable_symbols table, allowing the
# ExchangeScheduleMonitor to find the tracked tradables with a quick and
# simple query (select symbol from tradable_symbols where tracked = true).
# Note: when updating the database, the TradableTrackingManager suspends
# the ExchangeScheduleMonitor to avoid conflicts and, when finished, tells
# it to resume its operation/monitoring.
module TAT
  module TradableTrackingManager
    include Contracts::DSL, Service

    private

    ##### Hook method implementations

    def process(args = nil)
      if cleanup_needed then
        execute_complete_cycle
log_messages(debug: "finished 'execute_complete_cycle' #{DateTime.current}.")
      else
        process_tracking_changes
log_messages(debug: "finished 'process_tracking_changes' #{DateTime.current}.")
      end
      check_and_respond_to_sick_exchmon
log_messages(debug: "finished 'check_and_respond_to_sick_exchmon' #{DateTime.current}.")
      sleep MODERATE_PAUSE_SECONDS
    end

    protected

    SHORT_PAUSE_SECONDS, MODERATE_PAUSE_SECONDS = 2, 30

    # Clean up the database with respect to tradables marked as tracked that
    # are no longer tracked:
    #   - First, mark all tracked TradableSymbol records as NOT tracked.
    #   - Find the tradables that are currently tracked and mark the
    #     corresponding TradableSymbol records as tracked.
    post :update_time_set do last_update_time != nil end
    post :cleanup_time_set do last_cleanup_time != nil end
    def execute_complete_cycle
      raise "Fatal: abstract method: #{self.class} #{__method__}"
    end

  end
end
