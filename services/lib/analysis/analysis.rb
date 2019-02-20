require 'observer'
require 'ruby_contracts'

#!!!!!TO-DO: class description!!!!!
class Analysis
  include Observable, Contracts::DSL

  public

#!!!!!!!!REMINDER!!!!!!!!!: Ensure IS_TAT_SERVICE env. var. is defined!!!!!!
  attr_reader :mas_client, :analysis_error, :analysis_error_message

  # All resulting "AnalysisEvent"s
  attr_reader :resulting_events

  public

  ###  Basic operations

#!!!!DESIGN NOTE/TO-DO - with transactions and performance:
#currently, there is no 'user_id' in the *Trigger models/tables, which
#!!!implies that one (e.g., 'EOD_US_stocks') trigger will be shared by all
#!!!users in the system.  With the current implementation (in which the
#!!!processing of all "AnalysisSchedule"s occurs within one transactions)
#!!!this design implies that the analysis for all users configured with
#!!!that trigger will have there configured analysis schedules processed
#!!!within the same transaction, which (I believe) rules out the
#!!!possibility of, e.g., performing the analysis for user Joe concurrently
#!!!with the analysis for user Sally - not ideal!  Therefore, the design
#!!!should probably be changed such that each user has his own trigger
#!!!objects (so, e.g., there would be multiple EOD_US_stocks
#!!!"EventBasedTrigger"s instead of just one) so that the above concurrency
#!!!is possible.  Or the design should be changed such that the lock on the
#!!!*Trigger objects is moved lower in the hierarchy - e.g., to the
#!!!AnalysisSchedule or the AnalysisProfile, which would allow even
#!!!finer-grained locking/concurrency than the "users have their own
#!!!triggers" proposal.  (The 1st change seems easier to implement and may
#!!!provide adequate performance.)
  # For each schedule, s, in trigger.analysis_schedules for which s.active:
  #   For each profile, p, in s.analysis_profiles:
  #     For each evgen-profile, egp, in p.event_generation_profiles:
  #       Perform an analysis run on all tradables whose symbol is included
#!!!!!FIX: symbols no longer appears here!!!!!
  #         in 'symbols' (Array) for all egp.tradable_processor_specifications
  # If ! analysis_error: The resulting AnalysisRun objects will be saved to the
  # database and have a 'status' of "completed" or "failed".
  # If the database transaction that is invoked when saving the AnalysisRun
  # objects fails, this occurrence is logged (!!!as an 'error' or
  # 'warn'ing?!!!).  This failure status is not saved to the database,
  # since the transaction failure likely implies that either the database
  # server is down (or malfunctioning) or another thread or process already
  # had 'trigger' locked for processing and thus it should be left alone.
  pre  :trigger_in_database do |trigger|
    ! trigger.nil? && ! trigger.new_record? end
  pre  :trigger_ready do |trigger| trigger.ready? end
  pre  :no_transaction do |tr| tr.class.connection.open_transactions == 0 end
  post :closed_on_success do |res, tr| implies(! analysis_error, tr.closed?) end
  def run_triggered_analysis(trigger)
    @resulting_events = []
    handler = trigger_handler_for(trigger)
puts "trigger: #{trigger.inspect}"
    targeted_schedules = []
    handler.claim_and_execute do |t|
      t.analysis_schedules.select {|s| s.active}.each do |sched|
        targeted_schedules << sched
        sched.analysis_profiles.each do |an_prof|
          analyze_profile(an_prof)
        end
      end
    end
    if handler.error? then
      $log.error("Database transaction for #{trigger} failed: " +
                 "#{handler.exception}\n[need DB recovery plan]")
    else
      # There's no "handler" error, so notify any registered observers.
      targeted_schedules.each do |sched|
        sched.analysis_profiles.each do |an_prof|
          changed
          notify_observers(self, an_prof)
        end
      end
    end
  end

  # Perform an analysis run for all "EventGenerationProfile"s belonging to
#!!!!!FIX: symbols no longer appears here!!!!!
  # AnalysisProfile 'profile' on all tradables specified by 'symbols'.
  # If ! analysis_error: The resulting AnalysisRun objects will be saved to the
  # database and have a 'status' of "completed" or "failed".
  pre :prof_stored do |profile| ! profile.nil? && ! profile.new_record? end
  def run_analysis_on_profile(profile)
    @resulting_events = []
    profile.transaction(joinable: false, requires_new: true) do
      analyze_profile(profile)
      if ! analysis_error then
        changed
        notify_observers(self, profile)
      else
#!!!!TO-DO: Deal with the analysis error appropriately!!!
      end
    end
  rescue ActiveRecord::StaleObjectError => e
    $log.info("optimistic lock failed in #{__method__} for " +
               "#{e.inspect} -\nskipping (#{e})")
  rescue ActiveRecord::StatementInvalid => e
    $log.error("StatementInvalid exception in #{__method__} for " +
               "#{e} (#{e.inspect})\n[need DB recovery plan]")
  rescue ActiveRecord::ActiveRecordError => e
    $log.error("[#{self.class}.#{__method__}] transaction failed: " +
               "#{e} (#{e.inspect})\n[need DB recovery plan]")
  end

  private

  ###  Initialization

  pre  :arg_exists do |mascl| ! mascl.nil? end
  post :attr_exists do ! mas_client.nil? end
  def initialize(mascl)
    @mas_client = mascl
    @trigger_handler = {
        EventBasedTrigger => EventTriggerHandler.new,
        PeriodicTrigger => PeriodicTriggerHandler.new
    }
  end

  ###  Implementation - utilities

  def trigger_handler_for(trigger)
    result = @trigger_handler[trigger.class].clone
    result.trigger = trigger
    result
  end

  ###  Implementation

  # Perform an analysis run for all "EventGenerationProfile"s belonging to
#!!!!!FIX: symbols no longer appears here!!!!!
  # AnalysisProfile 'prof' on all tradables specified by 'symbols'.
  # Store the resulting AnalysisRun objects, and all associated persistent
  # objects created by the run in the database.
#!!!!!FIX: Figure out where to ensure (only in one place) that 'symbol'
#!!!!!is lower-case!!!!!
  pre :prof_in_database do |prof|
    ! prof.nil? && ! prof.new_record? end
  pre :in_transaction do |tr| tr.class.connection.open_transactions > 0 end
  post :runs_completed_on_success do |result, prof|
    implies(! analysis_error, prof.last_analysis_runs.all? { |r| r.completed? }) end
  post :runs_failed_on_error do |result, prof|
    implies(analysis_error, prof.last_analysis_runs.all? { |r| r.failed? }) end
  post :last_profile_run do |result, prof|
    prof.last_analysis_profile_run != nil end
  post :profile_run_added do |result, prof|
    prof.analysis_profile_runs.count > 0 end
  def analyze_profile(prof)
label = "#{self.class}.#{__method__}"
puts "[#{label}] symbol list for #{prof}: #{prof.symbol_list.inspect}"
    $log.debug("[#{self.class}.#{__method__}] symbol list for #{prof}: " +
               "#{prof.symbol_list.inspect}")
    @analysis_error = false
    @analysis_error_message = ""
    symbols = prof.symbol_list.symbol_values
puts "analysis_profile: symbols: #{symbols}"
    build_analysis_runs_for_profile(prof, symbols)
    prof.event_generation_profiles.each do |eg_prof|
      period_types = eg_prof.tradable_processor_specifications.map do |spec|
        spec.period_type_name
      end
      run = eg_prof.last_analysis_run
      # (map: processor_id => TPRun:)
      tprun_for_evntid = Hash[run.tradable_processor_runs.collect do |r|
        [r.processor_id, r]
      end]
      symbols.each do |symbol|
        lc_symbol = symbol.downcase
puts "analysis_profile - #{__LINE__} - lc_symbol: #{lc_symbol}"
        mas_client.request_analysis(eg_prof.tradable_processor_specifications,
          period_types, lc_symbol, eg_prof.start_date, eg_prof.end_date)
        if mas_client.communication_failed || mas_client.server_error then
          @analysis_error = true
          @analysis_error_message = mas_client.last_error_msg
        else
          results = mas_client.analysis_data
          @resulting_events.concat(results)
          load_analysis_events(tprun_for_evntid, lc_symbol, results)
        end
      end
    end
    # Save 'completed' results for later notification.
#!!!!Note: If one or more of the analyses attempted above failed, we might
#!!!!need to abandon all of these runs (prof.last_analysis_runs) and then,
#!!!!instead of marking all runs 'completed', mark them all 'failed'.
#!!!!(It might be better to filter-out/grab the "good" analyses so that the
#!!!!user receives the successful/valid signals, while reporting the failed
#!!!!analyses in "error-notifications" so that he is made aware of the problem.)
    save_analysis_results(prof)
  end

  # Build an AnalysisProfileRun and all of its component AnalysisRuns
  # for AnalysisProfile 'prof'.
  def build_analysis_runs_for_profile(prof, symbols)
#!!!!    expiration = DateTime.now +
    expiration = DateTime.current +
      Rails.configuration.x.default_expiration_duration
    if ! prof.save_results then
      expiration = DateTime.current
#!!!!      expiration = DateTime.now
    end
    profile_run = AnalysisProfileRun.new(user: prof.user,
      analysis_profile: prof, analysis_profile_name: prof.name,
      analysis_profile_client: prof.client_name,
      run_start_time: DateTime.current, expiration_date: expiration)
#!!!!      analysis_profile_client: prof.client_name, run_start_time: DateTime.now,
#!!!!      expiration_date: expiration)
    # (Set prof.notification_status to 'not_initialized':)
    profile_run.not_initialized!
    prof.last_analysis_profile_run = profile_run
    prof.event_generation_profiles.each do |eg_prof|
      build_analysis_run(eg_prof, profile_run, symbols)
    end
  end

  # Build an initial AnalysisRun, r, with 'status' of "running", for
  # evgen_profile and execute:
  #   evgen_profile.last_analysis_run = r
  pre :in_transaction do |egp| egp.class.connection.open_transactions > 0 end
  post :run_is_running do |result, egp| egp.last_analysis_run.running? end
  def build_analysis_run(evgen_profile, analysis_profile_run, symbols)
    # Create an AnalysisRun associated with 'evgen_profile':
    run = AnalysisRun.new(analysis_profile_run: analysis_profile_run,
                          start_date: evgen_profile.start_date,
                          end_date: evgen_profile.end_date)
    run.running!  # (Set run.status to 'running'.)
    evgen_profile.tradable_processor_specifications.each do |s|
      tprun = TradableProcessorRun.new(processor_id: s.processor_id,
                                       period_type: s.period_type)
      run.tradable_processor_runs << tprun
      s.tradable_processor_parameters.each do |param|
        tprun.tradable_processor_parameter_settings <<
          TradableProcessorParameterSetting.new(name: param.name,
                                              value: param.value)
      end
    end
    run.save!
    evgen_profile.last_analysis_run = run
  end

  # Mark, in the database, each AnalysisRun record associated with
  # profile.event_generation_profiles as 'completed' and ensure that each
  # run and all associated objects are saved to the database.
  def save_analysis_results(profile)
    profile.last_analysis_runs.each do |r|
      r.completed!
      #!!!!TO-DO: Where/when should we do: r.failed! for analysis failure?!!!
    end
    profile.save!
  end

  # Load analysis 'events' that resulted from calling
  # "<mas_client>.request_analysis" with 'symbol' into the correct
  # (according to each event's 'event_id' [AKA processor_id])
  # TradableProcessorRun, r, (accessed via 'tprun_for_evntid') by creating
  # a TradableEventSet with those events (type AnalysisEvent) and
  # associating that set with r.
  def load_analysis_events(tprun_for_evntid, symbol, events)
    set_for_id = {}
    # Create a TradableEventSet with 'symbol' for each TradableProcessorRun:
    tprun_for_evntid.keys.each do |id|
      set_for_id[id] = TradableEventSet.new(symbol: symbol)
      tprun_for_evntid[id].tradable_event_sets << set_for_id[id]
    end
    events.each do |e|
      set_for_id[e.event_id].analysis_events << e
    end
  end

end
