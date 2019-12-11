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
        debug("finished 'execute_complete_cycle' #{DateTime.current}.")
      else
        process_tracking_changes
        debug("finished 'process_tracking_changes' #{DateTime.current}.")
      end
      check_and_respond_to_sick_exchmon
      debug("finished 'check_and_respond_to_sick_exchmon' #{DateTime.current}")
      sleep MODERATE_PAUSE_SECONDS
    end

    protected

    attr_reader :continue_processing, :last_update_time,
      :last_cleanup_time, :exch_monitor_is_ill
    # The last recorded 'next_exch_close_datetime'
    attr_reader :last_recorded_close_time
    attr_reader :config

    TTM_LAST_TIME_KEY = 'ttm-last-update-time'

    SHORT_PAUSE_SECONDS, MODERATE_PAUSE_SECONDS = 2, 30

    # Clean up the database with respect to tradables marked as tracked that
    # are no longer tracked:
    #   - First, mark all tracked tradables as NOT tracked.
    #   - Find the tradables that are currently tracked and mark them
    #     as tracked.
    post :update_time_set do last_update_time != nil end
    post :cleanup_time_set do last_cleanup_time != nil end
    def execute_complete_cycle
      wait_until_exch_monitor_ready
      suspend_exch_monitor
      run_in_transaction do
        untrack_all_symbols
        track_used_symbols
      end
      @last_update_time = DateTime.current
      @last_cleanup_time = @last_update_time
      wake_exch_monitor
    end

    # Query for any tracking-related changes that have occurred since
    # 'last_update_time'.  If any are found, update the affected objects
    # and set 'last_update_time' to the current date/time.
    pre  :update_time_set do last_update_time != nil end
    post :update_time_set do last_update_time != nil end
    def process_tracking_changes
      run_in_transaction do   #!!!!TO-DO: abstractify (run_in_transaction)
        prepare_for_tracking_update
        if tracking_update_needed then
          wait_until_exch_monitor_ready
          suspend_exch_monitor
          perform_tracking_update
          set_message(TTM_LAST_TIME_KEY, DateTime.current.to_s)
          log_messages({TTM_LAST_TIME_KEY => DateTime.current.to_s})
          wake_exch_monitor
        end
      end
      begin
        lut = retrieved_message(TTM_LAST_TIME_KEY)
        if ! lut.nil? && ! lut.empty? then
          new_lut = DateTime.parse(lut)
          if new_lut > last_update_time then
            @last_update_time = DateTime.parse(lut)
          end
        end
      rescue StandardError => e
        raise "Fatal error - parse of time (#{lut.inspect}) failed: #{e}"
      end
    end

    # Does 'execute_complete_cycle' need to be called?
    def cleanup_needed
      last_cleanup_time.nil? || (cleanup_is_due && markets_are_closed)
    end

    # Has enough time passed since the last cleanup that a new cleanup is
    # needed?
    pre  :last_cleanup_exists do last_cleanup_time != nil end
    def cleanup_is_due
      # I.e.: (secs-since-epoch - secs-since-epoch-of:last-cleanup-time) <
      #          allocated-tracking-cleanup-interval[in-seconds]
      result = DateTime.current.to_i - last_cleanup_time.to_i >
      config.tracking_cleanup_interval
      result
    end

    protected  ### Exchange-monitor-related querying and control

    # Are all monitored exchanges currently closed?
    def markets_are_closed
      open_market_info.empty?
    end

    # Tell the exchange monitor to start running again.
    def wake_exch_monitor
      order_eod_exchange_monitoring_resumption
    end

    # If the current time is within PRE_CLOSE_TIME_MARGIN seconds from the
    # next closing time, sleep until a little while after the closing time
    # has passed.
    def wait_until_exch_monitor_ready
      now = DateTime.current
      previous_close_time = last_recorded_close_time
      @last_recorded_close_time = next_exch_close_datetime
      if last_recorded_close_time != nil then
        seconds_until_close = last_recorded_close_time.to_i - now.to_i
        # Check # of seconds after last close in case it's, e.g., 5 seconds
        # after an exchange just close (i.e., too soon):
        seconds_after_last_close = (
          (previous_close_time != nil) &&
          (previous_close_time != last_recorded_close_time)
        )?  now.to_i - previous_close_time.to_i: POST_CLOSE_TIME_MARGIN
        if
          seconds_until_close < PRE_CLOSE_TIME_MARGIN ||
            seconds_after_last_close < POST_CLOSE_TIME_MARGIN
          then
          sleep seconds_until_close + POST_CLOSE_TIME_MARGIN
        else
        end
      else
        check(last_recorded_close_time.nil?)
        # last_recorded_close_time == nil implies that no wait is needed.
      end
    end

    # Suspend the exchange monitor - Wait and verify that it enters the
    # suspended state before returning.
    post :suspended do
      implies(! exch_monitor_is_ill, eod_exchange_monitoring_suspended?) end
    def suspend_exch_monitor
      if ! eod_exchange_monitoring_suspended? then
        order_eod_exchange_monitoring_suspension
        sleep SHORT_PAUSE_SECONDS
        pause_count = 0
        while ! eod_exchange_monitoring_suspended? do
          if pause_count > 0 && pause_count % 5 == 0 then
            if
              eod_exchange_monitoring_unresponsive? ||
                eod_exchange_monitoring_terminated?
              then
              warn("#{EOD_EXCHANGE_MONITORING} service has terminated or " +
                   "is diseased")
              @exch_monitor_is_ill = true
              break
            end
          end
          # Loop until the reported state actually is "suspended".
          sleep SHORT_PAUSE_SECONDS
          pause_count += 1
        end
      end
    end

    # If exch_monitor_is_ill, respond by logging a report on the issue and
    # waiting for a while in the hope that an over-seer process will restart
    # the exchange monitor.
    def check_and_respond_to_sick_exchmon
      if exch_monitor_is_ill then
        pause_time = MODERATE_PAUSE_SECONDS * 3
        warn("#{EOD_EXCHANGE_MONITORING} service is not responding - pausing " +
          "for #{pause_time} seconds to wait for the process to be re-started.")
        sleep pause_time
        if
          ! (eod_exchange_monitoring_unresponsive? ||
             eod_exchange_monitoring_terminated?)
          then
          # exchange monitor has recovered.
          @exch_monitor_is_ill = false
        end
      end
    end

    ##### Hook methods

    # Mark all tradable-symbols as 'untracked'.
    def untrack_all_symbols
      raise "Fatal: abstract method: #{self.class} #{__method__}"
    end

    # Find all tradable-symbols that are currently used and mark each one as
    # 'tracked'.
    def track_used_symbols
      raise "Fatal: abstract method: #{self.class} #{__method__}"
    end

    # Prepare for a call to 'perform_tracking_update'.
    def prepare_for_tracking_update
      raise "Fatal: abstract method: #{self.class} #{__method__}"
    end

    # Does the tradable-tracking status need updating?
    def tracking_update_needed
      raise "Fatal: abstract method: #{self.class} #{__method__}"
    end

    # Bring the tradable-tracking status (in the "database") up to date
    def perform_tracking_update
      raise "Fatal: abstract method: #{self.class} #{__method__}"
    end

    # Run (yeild-to) the specified block within a "transaction".
    def run_in_transaction
      raise "Fatal: abstract method: #{self.class} #{__method__}"
    end

  end
end
