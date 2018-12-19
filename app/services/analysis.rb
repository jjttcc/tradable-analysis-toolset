require 'observer'
require 'ruby_contracts'

# Analysis service for tradables - i.e., a wrapping of
# '<mas-client>.request_analysis' and subsequent saving of all data
# structures (AnalysisRun, ..., AnalysisEvent) resulting from the run to
# persistent store, as well as notification with respect to the analysis
# results to any subscribers via the standard ruby Observable module
class Analysis
  include Observable, Contracts::DSL

  public

  attr_reader :mas_client, :error, :error_message

  # All resulting "AnalysisEvent"s
  attr_reader :resulting_events

  public

  ###  Basic operations

  # For each schedule, s, in trigger.analysis_schedules for which s.active:
  #   For each profile, p, in s.analysis_profiles:
  #     For each evgen-profile, egp, in p.event_generation_profiles:
  #       Perform an analysis run on all tradables whose symbol is included
  #         in 'symbols' (Array) for all egp.tradable_processor_specifications
  # If ! error: The resulting AnalysisRun objects will be saved to the
  # database and have a 'status' of "completed" or "failed".
  pre :trigger_in_database do |trigger|
    ! trigger.nil? && ! trigger.new_record? end
  pre :activated do |trigger| trigger.activated end
  pre :no_transaction do |tr| tr.class.connection.open_transactions == 0 end
  def run_triggered_analysis(trigger, symbols)
    @resulting_events = []
    trigger.analysis_schedules.select {|s| s.active}.each do |sched|
      sched.analysis_profiles.each do |an_prof|
#!!!TO-DO: Right now each call to 'analyze_profile' invokes a database
#!!!transaction to save the results for the current 'eg_prof'.  Decide if
#!!!this is wise, or should this entire loop execute within a transaction
#!!!to avoid persisting only partial results if a transaction fails in one
#!!!of the calls to 'analyze_profile'.
        analyze_profile(an_prof, symbols)
        if ! error then
          changed
          notify_observers(self, an_prof)
        else
#!!!!TO-DO: Deal with the error appropriately!!!  What to do here???!!!
        end
      end
    end
  end

  # Perform an analysis run for all "EventGenerationProfile"s belonging to
  # AnalysisProfile 'profile' on all tradables specified by 'symbols'.
  # If ! error: The resulting AnalysisRun objects will be saved to the
  # database and have a 'status' of "completed" or "failed".
  pre :prof_stored do |profile| ! profile.nil? && ! profile.new_record? end
  pre :no_transaction do |p| p.class.connection.open_transactions == 0 end
  def run_analysis_on_profile(profile, symbols)
    @resulting_events = []
    analyze_profile(profile, symbols)
    if ! error then
      changed
      notify_observers(self, profile)
    else
#!!!!TO-DO: Deal with the error appropriately!!!
    end
  end

  private

  ###  Initialization

  pre  :arg_exists do |mascl| ! mascl.nil? end
  post :attr_exists do ! mas_client.nil? end
  def initialize(mascl)
    @mas_client = mascl
  end

  ###  Implementation

  # Perform an analysis run for all "EventGenerationProfile"s belonging to
  # AnalysisProfile 'prof' on all tradables specified by 'symbols'.
  # Store the resulting AnalysisRun objects, and all associated persistent
  # objects created by the run in the database.
  pre :prof_in_database do |prof|
    ! prof.nil? && ! prof.new_record? end
  pre :no_transaction do |tr| tr.class.connection.open_transactions == 0 end
  post :runs_completed_on_success do |result, prof|
    implies(! error, prof.last_analysis_runs.all? { |r| r.completed? }) end
  post :runs_failed_on_error do |result, prof|
    implies(error, prof.last_analysis_runs.all? { |r| r.failed? }) end
  def analyze_profile(prof, symbols)
    @error = false
    @error_message = ""
    build_analysis_runs_for_profile(prof, symbols)
    if ! @error then
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
          mas_client.request_analysis(eg_prof.tradable_processor_specifications,
              period_types, symbol, eg_prof.start_date, eg_prof.end_date)
          if ! mas_client.communication_failed && ! mas_client.server_error then
            results = mas_client.analysis_data
            @resulting_events.concat(results)
            load_analysis_events(tprun_for_evntid, symbol, results)
          else
#!!!!To-be-decided [TBD]: Do we abandon the entire run here, or...???!!!!
            raise mas_client.last_error_msg
          end
        end
      end
      # Save 'completed' results for later notification.
#!!!!Note: If one or more of the analyses attempted above failed, we might
#!!!!need to abandon all of these runs (prof.last_analysis_runs) and then,
#!!!!instead of marking all runs 'completed', mark them all 'failed'.
      save_analysis_results(prof)
    end
  end

  # Build all AnalysisRuns needed for AnalysisProfile 'prof'.
  def build_analysis_runs_for_profile(prof, symbols)
    prof.transaction do
puts "<<<HERE!!!!!!!!>>>"
puts "barufp - prof: #{prof.inspect}"
puts "barufp - prof.notaddrs.count: #{prof.notification_addresses.count}"
      # Build a Notification for each of prof's notification_addresses:
      prof.notification_addresses.each do |addr|
        notification = Notification.new(
          contact_identifier: addr.contact_identifier, medium_type:
          addr.medium_type, user: prof.user)
        notification.notification_source = prof
        notification.initial!   # i.e., set notification.status to initial
puts "prof.notifications.count: #{prof.notifications.count}"
      end
      prof.event_generation_profiles.each do |eg_prof|
        build_analysis_run(eg_prof, symbols)
        prof.notifications.each do |n|
          create_notification_for(n, eg_prof.last_analysis_run)
        end
      end
    end
  rescue ActiveRecord::RecordInvalid => exception
    @error = true
    @error_message = exception.message
    prof.last_analysis_runs.each do |r|
      r.failed!
    end
  end

# Create a notification for Notification 'n' (as child of 'n'), using
# information from 'analysis_run'.
#!!!!!!Move this down a bit after implementing...!!!
def create_notification_for(n, analysis_run)
end

  # Build an initial AnalysisRun, r, with 'status' of "running", for
  # evgen_profile and execute:
  #   evgen_profile.last_analysis_run = r
  pre :in_transaction do |egp| egp.class.connection.open_transactions > 0 end
  post :run_is_running do |result, egp| egp.last_analysis_run.running? end
  def build_analysis_run(evgen_profile, symbols)
    run_start = DateTime.now
    # Create an AnalysisRun associated with 'evgen_profile':
    run = AnalysisRun.new(user: evgen_profile.user,
      start_date: evgen_profile.start_date, end_date: evgen_profile.end_date,
      analysis_profile_name: evgen_profile.analysis_profile.name,
      analysis_profile_client: evgen_profile.client_name,
      run_start_time: run_start)
    run.running!  # (Set run.status to 'running'.)
#!!!make-it-so: run.keep = evgen_profile.analysis_profile.save_results
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
    profile.transaction do
      profile.last_analysis_runs.each do |r|
        r.completed!
      end
      profile.save!
    end
  rescue ActiveRecord::RecordInvalid => exception
    @error = true
    @error_message = exception.message
    profile.last_analysis_runs.each do |r|
      r.failed!
    end
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

  # Create and save an initial AnalysisRun record, with 'status' of
  # "running", for each of profile.event_generation_profiles.
  def obsolete__donotuse___new_analysis_run(profile, symbols)
    result = nil
    run_start = DateTime.now
    profile.event_generation_profiles.each do |egprof|
#!!!!stubbed value - until status enum is set up:
status = 1
      run = AnalysisRun.new(user: profile.user, status: status,
        start_date: egprof.start_date, end_date: egprof.end_date,
        analysis_profile_name: egprof.analysis_profile.name,
        analysis_profile_client: egprof.client_name, run_start_time: run_start)
      egprof.tradable_processor_specifications.each do |s|
        tprun = TradableProcessorRun.new(analysis_run: run,
          processor_id: s.processor_id, period_type: s.period_type)
        symbols.each do |s|
          TradableEventSet.new(tradable_processor_run: tprun, symbol: s)
        end
      end
      run.save!
    end
  end

end

=begin
= Observable

(from ruby site)
------------------------------------------------------------------------------
The Observer pattern (also known as publish/subscribe) provides a simple
mechanism for one object to inform a set of interested third-party objects
when its state changes.

== Mechanism

The notifying class mixes in the Observable module, which provides the methods
for managing the associated observer objects.

The observable object must:
* assert that it has #changed
* call #notify_observers

An observer subscribes to updates using Observable#add_observer, which also
specifies the method called via #notify_observers. The default method for
#notify_observers is #update.

=== Example

The following example demonstrates this nicely.  A Ticker, when run,
continually receives the stock Price for its @symbol.  A Warner is a general
observer of the price, and two warners are demonstrated, a WarnLow and a
WarnHigh, which print a warning if the price is below or above their set
limits, respectively.

The update callback allows the warners to run without being explicitly called.
 The system is set up with the Ticker and several observers, and the observers
do their duty without the top-level code having to interfere.

Note that the contract between publisher and subscriber (observable and
observer) is not declared or enforced.  The Ticker publishes a time and a
price, and the warners receive that.  But if you don't ensure that your
contracts are correct, nothing else can warn you.

  require "observer"

  class Ticker    ### Periodically fetch a stock price.
    include Observable

    def initialize(symbol)
      @symbol = symbol
    end

    def run
      last_price = nil
      loop do
  price = Price.fetch(@symbol)
  print "Current price: #{price}\n"
  if price != last_price
    changed     # notify observers
    last_price = price
    notify_observers(Time.now, price)
  end
  sleep 1
      end
    end
  end

  class Price   ### A mock class to fetch a stock price (60 - 140).
    def self.fetch(symbol)
      60 + rand(80)
    end
  end

  class Warner    ### An abstract observer of Ticker objects.
    def initialize(ticker, limit)
      @limit = limit
      ticker.add_observer(self)
    end
  end

  class WarnLow < Warner
    def update(time, price)   # callback for observer
      if price < @limit
  print "--- #{time.to_s}: Price below #@limit: #{price}\n"
      end
    end
  end

  class WarnHigh < Warner
    def update(time, price)   # callback for observer
      if price > @limit
  print "+++ #{time.to_s}: Price above #@limit: #{price}\n"
      end
    end
  end

  ticker = Ticker.new("MSFT")
  WarnLow.new(ticker, 80)
  WarnHigh.new(ticker, 120)
  ticker.run

Produces:

  Current price: 83
  Current price: 75
  --- Sun Jun 09 00:10:25 CDT 2002: Price below 80: 75
  Current price: 90
  Current price: 134
  +++ Sun Jun 09 00:10:25 CDT 2002: Price above 120: 134
  Current price: 134
  Current price: 112
  Current price: 79
  --- Sun Jun 09 00:10:25 CDT 2002: Price below 80: 79
------------------------------------------------------------------------------
= Instance methods:

  add_observer
  changed
  changed?
  count_observers
  delete_observer
  delete_observers
  notify_observers

=end
