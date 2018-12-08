require 'observer'
require 'ruby_contracts'

# Analysis service for tradables - i.e., a wrapping of
# '<mas-client>.request_analysis' and subsequent notification and delivery
# with respect to the analysis results to subscribers via the Observable
# module from the ruby standard library.
class Analysis
  include Observable, Contracts::DSL

  public

  attr_reader :mas_client, :error, :resulting_events

  public

  ###  Basic operations

  # For each schedule, s, in trigger.analysis_schedules for which s.active:
  #   For each profile, p, in s.analysis_profiles:
  #     For each evgen-profile, egp, in p.event_generation_profiles:
  #       Perform an analysis run on the tradable IDd by 'symbol' for all
  #         egp.tradable_processor_specifications
  pre :trigger_in_database do |trigger|
    ! trigger.nil? && ! trigger.new_record? end
  pre :activated do |trigger| trigger.activated end
  def run_triggered_analysis(trigger, symbol)
    @resulting_events = []
    trigger.analysis_schedules.select {|s| s.active}.each do |sched|
      sched.analysis_profiles.each do |prof|
        if ! prof.save_results then
          create_analysis_run(prof)
        end
        analyze_profile(prof, symbol)
        if ! error then
          changed
puts "[rta] notify_observers for #{prof}"
          notify_observers(self, prof)
          if ! prof.save_results then
            mark_analysis_run_completed(prof)
          end
        else
          if ! prof.save_results then
            mark_analysis_run_failed(prof)
          end
#!!!!TO-DO: Deal with the error appropriately!!!
        end
      end
    end
  end

  # Perform an analysis run for all "EventGenerationProfile"s belonging to
  # AnalysisProfile 'profile' on 'symbol'.
  pre :prof_stored do |profile| ! profile.nil? && ! profile.new_record? end
  def run_analysis_on_profile(profile, symbol)
    @resulting_events = []
    analyze_profile(profile, symbol)
    if ! error then
      changed
puts "[raop] notify_observers for #{profile}"
      notify_observers(self, profile)
    else
#!!!!TO-DO: Deal with the error appropriately!!!
    end
  end

#!!!!Question: Which model class should persistent events be associated with?!!!
#!!!!Perhaps that class should be able to access $client.analysis_data!!!!
#!!!!Update on the above: A new set of models is emerging to handle/persist
#!!!!the results of an "analysis run".  This set likely fits into the
# !!!!  classes/associations implied by the above question/answer!!!!
#!!!!Maybe (or maybe not) that class should be subscribed/notified (via!!!!
# !!!!  'notify_observers')!!!! (probably not, since Analysis knows about it
# !!!!! directly and can thus notify it directly!!!!!!!!!!!!#####!!!!!
#!!!!!Results for the last analysis run with respect to 'object'

  private

  ###  Initialization

  pre  :arg_exists do |mascl| ! mascl.nil? end
  post :attr_exists do ! mas_client.nil? end
  def initialize(mascl)
    @mas_client = mascl
  end

  ###  Implementation

  # Perform an analysis run for all "EventGenerationProfile"s belonging to
  # AnalysisProfile 'prof' on 'symbol'.
  pre :prof_in_database do |prof|
    ! prof.nil? && ! prof.new_record? end
  def analyze_profile(prof, symbol)
    prof.event_generation_profiles.each do |eg_prof|
      period_types = eg_prof.tradable_processor_specifications.map do |spec|
        spec.period_type_name
      end
      mas_client.request_analysis(eg_prof.tradable_processor_specifications,
                                  period_types, symbol,
                                  eg_prof.start_date, eg_prof.end_date)
      if ! mas_client.communication_failed && ! mas_client.server_error then
        results = mas_client.analysis_data
        @resulting_events.concat(results)
        eg_prof.last_analysis_results = results
      else
        raise mas_client.last_error_msg
      end
    end
  end

  # Create and save an initial AnalysisRun record for each of
  # profile.event_generation_profiles.
  def create_analysis_run(profile)
#!!!!!Don't forget to begin a transaction!!!!
puts "create_analysis_run stub for #{profile}"
#!!!!!Don't forget to close the transaction!!!!
  end

  # Mark, in the database, each AnalysisRun record associated with
  # profile.event_generation_profiles as 'failed'.
  def mark_analysis_run_failed(profile)
#!!!!!Don't forget to begin a transaction!!!!
puts "mark_analysis_run_failed stub for #{profile}"
#!!!!!Don't forget to close the transaction!!!!
  end

  # Mark, in the database, each AnalysisRun record associated with
  # profile.event_generation_profiles as 'completed'.
  def mark_analysis_run_completed(profile)
#!!!!!Don't forget to begin a transaction!!!!
puts "mark_analysis_run_completed stub for #{profile}"
#!!!!!Don't forget to close the transaction!!!!
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
