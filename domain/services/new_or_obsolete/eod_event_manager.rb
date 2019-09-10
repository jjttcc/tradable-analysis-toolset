=begin
#!!!!I believe these "require"s can all be deleted - do it soon!!!!!:
require 'set'
require 'ruby_contracts'
require 'subscriber'
require 'tat_util'
require 'service_tokens'
require 'tat_services_facilities'
require 'eod_data_wrangler'
require 'concurrent-ruby'
=end


# Management of EOD data-ready events
# Subscribes to the EOD_DATA_CHANNEL for "eod-data-ready" notifications;
# obtains the current list, slist, of symbols to be processed and, for
# each symbol, s, in slist:
#   for each 'available' trigger (EventBasedTrigger), t, that uses s:
#     - t.activated = true
#     - t.save
# When the above processing is complete, saves slist to the messaging system
# and publishes the key for that list to the TRIGGERED_EVENTS_CHANNEL.
#[!!!!Note: Copy/paste/adapt (from EODRetrievalManager) still in progress -
# i.e., some code/attributes are leftover from EODRetrievalManager - still
# need to be changed re. EODEventManager (e.g., eod_check_key)!!!!!]
class EODEventManager < Subscriber
  include Service

  public  ###  Access

  attr_reader :service_tag, :eod_data_ready_key, :log
  # List of symbols found to be "ready" upon EOD_DATA_CHANNEL notice:
  attr_reader :target_symbols_count

  public  ###  Basic operations

  def execute
    handle_unfinished_processing
#!!!template method needed (ordered_eod_event_triggering_run_state -> xxx):
    while ordered_eod_event_triggering_run_state != SERVICE_TERMINATED
      wait_for_and_process_eod_event
      sleep MAIN_LOOP_PAUSE_SECONDS
    end
  end

  private

  def wait_for_and_process_eod_event
    wait_for_notification
    if some_kind_of_template_method then
      error_msg = "failed to obtain 'EOD-templated-something_or_other' key"
      error(error_msg)
      raise error_msg
    end
    handle_the_work____template_method
  end

  post :target_symbols_count do ! target_symbols_count.nil? end
#!!!templatize:
  post :key_set do data_ready_key != nil end
  def wait_for_notification
    debug("#{self.class} subscribing to channel: " +
         "#{default_subscription_channel} (#{self.inspect})")
    subscribe_once do
#!!!templatize:
      @eod_data_ready_key = last_message
    end
  end

  def handle_unfinished_processing
#!!!refactor?!!!
  end

  def handle_the_work____template_method
  end

  private

  MAIN_LOOP_PAUSE_SECONDS = 15

  require 'logger'

  pre :config_exists do |config| config != nil end
  post :log do log != nil end
  def initialize(config, the_log = nil)
    @log = the_log
    if @log.nil? then
      @log = Logger.new(STDOUT)
    end
    $log = @log
    @run_state = SERVICE_RUNNING
    @service_tag = EOD_EVENT_TRIGGERING
    initialize_message_brokers(config)
    initialize_pubsub_broker(config)
    set_subs_callback_lambdas
    super(EOD_DATA_CHANNEL)  # i.e., subscribe channel
    create_status_report_timer
    @status_task.execute
  end

  post :subs_callbacks do subs_callbacks != nil end
  def set_subs_callback_lambdas
    @subs_callbacks = {}
    @subs_callbacks[:postproc] = lambda do
      #!!!!figure out the right *_key!!!:
      @target_symbols_count = queue_count(eod_something_or_other_template_key)
log.debug("[ERM] #{__method__} - tgtsymscnt: #{@target_symbols_count}")
    end
  end

end
