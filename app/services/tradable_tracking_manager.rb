# Implementation of the tradable-tracking service (
# TAT::TradableTrackingManager) using a database and ActiveRecord
# The tradable_symbols table is used to store the information as to which
# tradables are "tracked".
class TradableTrackingManager
  include Contracts::DSL, TAT::TradableTrackingManager

  protected

  # Use this module to allow RAM-hungry database operations to be
  # performed in a child process and thus released (RAM) when completed:
  include ForkedDatabaseExecution

  ##### Hook method implementations

  def untrack_all_symbols
    TradableSymbol.where(tracked: true).update_all(tracked: false)
  end

  def track_used_symbols
    tracked = {}
    AnalysisProfile.all.each do |p|
      p.tracked_tradable_ids.each do |symbol_id|
        tracked[symbol_id] = true
      end
    end
    log_messages(tus: "#{__method__} tracking ids: #{tracked.keys.inspect}")
    TradableSymbol.where(id: tracked.keys).update_all(tracked: true)
  end

  def prepare_for_tracking_update
    @updated_symbol_ids = ids_of_updated_tradables
  end

  def tracking_update_needed
      ! @updated_symbol_ids.empty?
  end

  def perform_tracking_update
    track(updated_symbol_ids)
  end

  # Run (yeild-to) the specified block within a "transaction".
  def run_in_transaction
    execute_with_wait do
      ActiveRecord::Base.transaction do
        yield
      end
    end
  end

  ##### Database queries and updates

  # Array: id of each TradableSymbol that has been updated since
  # 'last_update_time'
  def ids_of_updated_tradables
    ids_of_untracked_tradables_for(updated_symbol_list_owners)
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
      log_messages(uslo: "sla: #{sla.inspect}")
      owner = sla.symbol_list_user
      if owner != nil then
        if owner.in_use? then
          result_hash[owner] = true
        end
      else
        log_messages(uslo:
          "owner with id: #{sla.symbol_list_user_id} appears to NOT exist.")
      end
    end
    if ! result_hash.empty? then
      log_messages(uslo: "#{__method__} returning:" +
                   "#{result_hash.keys.inspect} (#{DateTime.current})")
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

  #####  Initialization

  include LoggingFacilities

  pre  :config_exists do |config| config != nil end
  post :log_config_etc_set do invariant end
  post :logging_off do ! logging_on end
  def initialize(config)
    super(config)
    turn_off_logging
    @do_not_re_establish_connection = true
    # Explicitly close the database connection so that the parent process
    # does not hold onto the database. (See ForkedDatabaseExecution .)
    ActiveRecord::Base.remove_connection
  end

end
