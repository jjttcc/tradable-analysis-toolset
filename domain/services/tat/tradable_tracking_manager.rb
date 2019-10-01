# Manager responsible for identifying tradables that are being used and
# marking them as such in the tradable_symbols table, allowing the
# ExchangeScheduleMonitor to find the tracked tradables with a quick and
# simple query (select symbol from tradable_symbols where tracked = true).
# Note: when updating the database, the TradableTrackingManager suspends
# the ExchangeScheduleMonitor to avoid conflicts and, when finished, tells
# it to resume its operation/monitoring.
module TAT
  module TradableTrackingManager
    include Service

    private

    ##### Hook method implementations

    def process(args = nil)
      if cleanup_needed then
        execute_complete_cycle
        puts "finished CLEANING up #{DateTime.current}."
        STDOUT.flush
      else
        process_tracking_changes
      end
      check_and_respond_to_sick_exchmon
      sleep MODERATE_PAUSE_SECONDS
    end

    protected

    SHORT_PAUSE_SECONDS, MODERATE_PAUSE_SECONDS = 2, 30

  end
end
