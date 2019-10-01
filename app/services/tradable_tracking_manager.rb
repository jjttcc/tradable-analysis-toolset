# Manager responsible for identifying tradables that are being used and
# marking them as such in the tradable_symbols table, allowing the
# ExchangeScheduleMonitor to find the tracked tradables with a quick and
# simple query (select symbol from tradable_symbols where tracked = true).
# Note: when updating the database, the TradableTrackingManager suspends
# the ExchangeScheduleMonitor to avoid conflicts and, when finished, tells
# it to resume its operation/monitoring.
class TradableTrackingManager
  include Contracts::DSL, TAT::TradableTrackingManager

  # Use this module to allow RAM-hungry database operations to be
  # performed in a child process and thus released (RAM) when completed:
  include ForkedDatabaseExecution

#!!!!!obsolete - remove:
  # Execute an infinite loop in which the needed actions are periodically
  # performed.
  def old__execute
    while continue_processing do
      if cleanup_needed then
        execute_complete_cycle
      else
        process_tracking_changes
      end
      check_and_respond_to_sick_exchmon
      sleep MODERATE_PAUSE_SECONDS
    end
  end

  protected  ###  Top-level implementation

  # Clean up the database with respect to tradables marked as tracked that
  # are no longer tracked:
  #   - First, mark all tracked TradableSymbol records as NOT tracked.
  #   - Find the tradables that are currently tracked and mark the
  #     corresponding TradableSymbol records as tracked.
  post :update_time_set do last_update_time != nil end
  post :cleanup_time_set do last_cleanup_time != nil end
  def execute_complete_cycle
    if verbose then
      log_verbose_messages(debug: "[#{__method__}] CLEANING UP - " +
                           "#{DateTime.current}.", lvma2test: "(useless goo)")
    end
    log_verbose_messages(debug: "waiting for Godot")
    wait_until_exch_monitor_ready
    log_verbose_messages(debug: "suspending Godot")
    suspend_exch_monitor
    log_verbose_messages(debug: "executing with 'wait'")
    execute_with_wait do
      ActiveRecord::Base.transaction do
puts "untracking all symbols...#{DateTime.current}"
STDOUT.flush
        untrack_all_symbols
puts "tracking symbols...#{DateTime.current}"
STDOUT.flush
        track_used_symbols
puts "FINISHED tracking symbols...#{DateTime.current}"
STDOUT.flush
      end
    end
    @last_update_time = DateTime.current
    @last_cleanup_time = @last_update_time
    log_verbose_messages(debug: "waking Godot")
    wake_exch_monitor
  end

  # Query for any tracking-related changes that have occurred since
  # 'last_update_time'.  If any are found, update the affected
  # TradableSymbols and set 'last_update_time' to the current date/time.
  pre  :update_time_set do last_update_time != nil end
  post :update_time_set do last_update_time != nil end
  def process_tracking_changes
    execute_with_wait do
      ActiveRecord::Base.transaction do
        updated_symbol_ids = ids_of_updated_tradables
        if ! updated_symbol_ids.empty? then
          wait_until_exch_monitor_ready
          suspend_exch_monitor
          track(updated_symbol_ids)
          set_message(TTM_LAST_TIME_KEY, DateTime.current.to_s)
#!!!rm:          log_messages([TTM_LAST_TIME_KEY, DateTime.current.to_s])
          wake_exch_monitor
        end
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

  # If the current time is within PRE_CLOSE_TIME_MARGIN seconds from the
  # next closing time, sleep until a little while after the closing time
  # has passed.
  def wait_until_exch_monitor_ready
    now = DateTime.current
    previous_close_time = last_recorded_close_time
    @last_recorded_close_time = next_exch_close_datetime
puts "Waiting for ex mon to become ready (#{DateTime.current})"
puts "prevct, last_rct: #{previous_close_time}, #{last_recorded_close_time}"
STDOUT.flush
    if last_recorded_close_time != nil then
#!!!!![Check this section for correctness:
      seconds_until_close = last_recorded_close_time.to_i - now.to_i
      # Check # of seconds after last close in case it's, e.g., 5 seconds
      # after an exchange just close (i.e., too soon):
      seconds_after_last_close = (
        (previous_close_time != nil) &&
        (previous_close_time != last_recorded_close_time)
      )?  now.to_i - previous_close_time.to_i: POST_CLOSE_TIME_MARGIN
puts "secs until ct: #{seconds_until_close}"
puts "secs after lct: #{seconds_after_last_close}"
      if
        seconds_until_close < PRE_CLOSE_TIME_MARGIN ||
          seconds_after_last_close < POST_CLOSE_TIME_MARGIN
      then
puts "I'm waiting for #{seconds_until_close + POST_CLOSE_TIME_MARGIN}....." +
"(#{DateTime.current})"
STDOUT.flush
        sleep seconds_until_close + POST_CLOSE_TIME_MARGIN
      else
puts "I'm NOT waiting (#{DateTime.current})"
STDOUT.flush
      end
#!!!!!end (Check...)]
    else
      check(last_recorded_close_time.nil?)
      # last_recorded_close_time == nil implies that no wait is needed.
    end
puts "finished waiting (or NOT waiting)(#{DateTime.current})"
STDOUT.flush
  end

  # Suspend the exchange monitor - Wait and verify that it enters the
  # suspended state before returning.
  post :suspended do
    implies(! exch_monitor_is_ill, eod_exchange_monitoring_suspended?) end
  def suspend_exch_monitor
    if ! eod_exchange_monitoring_suspended? then
puts "#{self.class}.#{__method__} calling 'order_eod_exchange_monitoring_suspension'"
      order_eod_exchange_monitoring_suspension
      sleep SHORT_PAUSE_SECONDS
puts "waiting for exch. mon. to suspend itself..."
STDOUT.flush
      pause_count = 0
      while ! eod_exchange_monitoring_suspended?
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
puts "FINISHED waiting for exch. mon. to suspend itself..."
STDOUT.flush
    end
  end

  # Tell the exchange monitor to start running again.
  def wake_exch_monitor
    order_eod_exchange_monitoring_resumption
  end

  protected  ### Database queries and updates

  # Mark all tradable-symbols as 'untracked'.
  def untrack_all_symbols
    TradableSymbol.where(tracked: true).update_all(tracked: false)
  end

  # Find all tradable-symbols that are currently used and mark each one as
  # 'tracked'.
  def track_used_symbols
    tracked = {}
    AnalysisProfile.all.each do |p|
      p.tracked_tradable_ids.each do |symbol_id|
        tracked[symbol_id] = true
      end
    end
puts "#{__method__} tracking ids: #{tracked.keys.inspect}"
    TradableSymbol.where(id: tracked.keys).update_all(tracked: true)
  end

  # Array: id of each TradableSymbol that has been updated since
  # 'last_update_time'
  def ids_of_updated_tradables
    updated_owners = updated_symbol_list_owners
    ids_of_untracked_tradables_for(updated_owners)
  end

  # All owners of an updated (new or changed) SymbolList
  def updated_symbol_list_owners
    result_hash = {}
    # (I.e., hash table of updated "SymbolListAssignment"s:)
    updated_symlist_assignments = Hash[
      SymbolListAssignment.updated_since(last_update_time).map do |sla|
        [sla.id, sla]
      end
    ]
    # The goal here is to find "SymbolList"s whose 'symbols' attribute has
    # been updated - added-to, removed-from, etc.:
    updated_symlists = SymbolList.updated_since(last_update_time)
    # Add any non-duplicate SymbolListAssignment objects referenced by
    # updated_symlists to updated_symlist_assignments.
    updated_symlists.each do |sl|
      sl.symbol_list_assignments.each do |sla|
        updated_symlist_assignments[sla.id] = sla
      end
    end
    # Insert all 'in_use?' owners of updated_symlist_assignments.values
    # (SymbolListAssignment objects) into result_hash.
    updated_symlist_assignments.values.each do |sla|
puts "sla: #{sla.inspect}"
      owner = sla.symbol_list_user
      if owner != nil then
        if owner.in_use? then
          result_hash[owner] = true
        end
      else
puts "owner with id: #{sla.symbol_list_user_id} appears to NOT exist."
      end
    end
if ! result_hash.empty? then
puts "#{__method__} returning:#{result_hash.keys.inspect} (#{DateTime.current})"
end
    result_hash.keys
  end

  # Array: id of each TradableSymbol owned by one (or more) element of
  # 'ts_owners' for which tracked == false
  def ids_of_untracked_tradables_for(ts_owners)
    tracked = {}
    # Use a hash table to eliminate duplicate ids.
    ts_owners.each do |o|
      o.tracked_tradable_ids.each do |symbol_id|
        tracked[symbol_id] = true
      end
    end
    # (Only include ids for which tracked == false (untracked).)
    result = TradableSymbol.where({id: tracked.keys, tracked: false})
    result
  end

  pre :one_or_more do |sym_ids| sym_ids != nil && sym_ids.count > 0 end
  # Mark, in the database, the specified tradable-symbols as "tracked".
  def track(affected_symbol_ids)
    TradableSymbol.where(id: affected_symbol_ids).update_all(tracked: true)
  end

  private

  attr_reader :continue_processing, :last_update_time,
    :last_cleanup_time, :exch_monitor_is_ill
  # The last recorded 'next_exch_close_datetime'
  attr_reader :last_recorded_close_time
  attr_reader :config

  TTM_LAST_TIME_KEY = 'ttm-last-update-time'

  private    ###  Initialization

include LoggingFacilities

def db_key_report
  puts "all keys:", all_logging_keys.join(",")
  print "ALL KEYS: <", LoggingFacilities::all_logging_keys.join(">, <"), ">\n"
  print "MY KEY: '", logging_key_for(service_tag), "'\n"
end

  pre  :config_exists do |config| config != nil end
  post :log_config_etc_set do invariant end
  post :logging_off do ! logging_on end
  def initialize(config)
    turn_off_logging
    initialize_message_brokers(config)
    @config = config
    @log = config.message_log
    @error_log = config.error_log
    @last_update_time = nil
    @run_state = SERVICE_RUNNING
    @service_tag = MANAGE_TRADABLE_TRACKING
db_key_report
    @log = config.message_log
puts "TTM log is a #{@log.class} [#{@log.inspect}]"
puts "TTM self.log is a #{self.log.class} [#{self.log.inspect}]"
    self.log.change_key(service_tag)
puts "TTM init - log: #{log.inspect}"
    set_message(TTM_LAST_TIME_KEY, nil)
#!!!rm:    log_messages({TTM_LAST_TIME_KEY => nil})
    @last_cleanup_time = nil
    @last_recorded_close_time = next_exch_close_datetime
    @continue_processing = true
    @exch_monitor_is_ill = false
    @do_not_re_establish_connection = true
    # Explicitly close the database connection so that the parent process
    # does not hold onto the database. (See ForkedDatabaseExecution .)
    ActiveRecord::Base.remove_connection
    create_status_report_timer
    # The 'status_task' will asynchronously periodically report our status.
    @status_task.execute
  end

end
