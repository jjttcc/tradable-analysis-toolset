require 'publisher'
require 'eod_communications_facilities'
require 'tat_services_facilities'

# Encapsulation of services intercommunications from the POV of end-of-day
# data retrieval
class EODRetrievalInterCommunications < Publisher
  include Contracts::DSL, EODCommunicationsFacilities, TatServicesFacilities

  public

  #####  Access

  attr_reader :subscription_channel, :publication_channel
  attr_reader :owned_queue_key_query

#!!!!TO-DO: search for and address: #!!!!!!message-broker communication!!!!!!
#!!!!TO-DO: look for other comms not yet marked/commented, and address!!!!!!!

  # Symbols still in "our" queue (pending) and thus needing processing
  def pending_symbols
    q_key = our_queue_key
    result = queue_contents(q_key)
    debug("#{self.class}.#{__method__}, key: "\
               "#{q_key} returning #{result}")
    result
  end

  # contents of the "EOD-check"-key queue
  def eod_check_keys
    eod_check_contents
  end

  # Count of symbols "our" 'EOD-check' symbols queue
  # If 'key.nil?', obtain the key for the queue via 'owned_queue_key_query'.
  def eod_symbols_count(key = nil)
    if key.nil? then
      # Make sure our key is up to date.
      @our_queue_key = nil
      q_key = our_queue_key
    else
      q_key = key
    end
    queue_count(q_key)
  end

  # Contents of "our" 'EOD-check' symbols queue
  # If 'key.nil?', obtain the key for the queue via 'owned_queue_key_query'.
  def eod_symbols(key = nil)
    if key.nil? then
      # Make sure our key is up to date.
      @our_queue_key = nil
      q_key = our_queue_key
    else
      q_key = key
    end
    queue_contents(q_key)
  end

  #####  Message-broker queue modification

  # Traverse "our" symbols queue and for each symbol, s, in the queue for
  # which the associated data has been fully updated, move s to the queue
  # identified by 'target_queue_key' - that is:
  #   While we've not traversed the entire queue: for the current head, h:
  #     o if h is now up to date (yield(h) is true), move h from "our"
  #       queue to the tail of the target ('target_queue_key') queue
  #     o else rotate "our" queue so that h becomes the tail of the queue
  #       and the former second element becomes the head.
  pre  :target_key_good do |target_queue_key| target_queue_key != nil end
  def process_symbols_queue(target_queue_key)
    q_key = our_queue_key
    count = queue_count(q_key)
    (0 .. count - 1).each do |i|
      head = queue_head(q_key)
      if yield(head) then   # If "we" are finished with 'head'
        # Move the head of "our" queue to the target queue tail (if
        # possible, as an atomic operation).
        move_head_to_tail(q_key, target_queue_key)
      else    # (Not yet finished with 'head')
        # (Move the head of "our" queue to the tail [of "our" queue].)
        rotate_queue(q_key)
      end
    end
  end

  #####  Message-broker state-changing operations

  # Notify all who are interested that the EOD-retrieval action has completed.
  def notify_of_completion(notification_key)
    send_eod_retrieval_completed(notification_key)
  end

  # Notify all who are interested that the EOD-retrieval action timed out.
  def notify_of_timeout(notification_key, msg)
    send_eod_retrieval_timed_out(notification_key, msg)
  end

  # Notify, via publication, all who are interested that an EOD-data update
  # has been completed for one or more tradables.  If 'enqueue_key', then call
  # 'enqueue_eod_ready_key' with 'notification_key' as well.
  def notify_of_update(notification_key, enqueue_key = false)
    publish notification_key
    debug("published '#{notification_key}'")
    if enqueue_key then
      enqueue_eod_ready_key(notification_key)
    end
  end

  protected

  attr_accessor :owner, :error_log
  attr_writer   :owned_queue_key_query

  def our_queue_key
    if @our_queue_key.nil? then
      @our_queue_key = owner.send(owned_queue_key_query)
    end
    @our_queue_key
  end

  post :invariant do invariant end
  def initialize(owner:, my_key_query:)
    self.owner = owner
    # For 'debug', 'error', ...:
    self.error_log = owner.send(:error_log)
    self.owned_queue_key_query = my_key_query
    @subscription_channel = TatServicesConstants::EOD_CHECK_CHANNEL
    @publication_channel = TatServicesConstants::EOD_DATA_CHANNEL
    initialize_message_brokers(owner.config)
    initialize_pubsub_broker(owner.config)
    super(publication_channel)
  end

  #####  Invariant

  # (self has an owner and an owned_queue_key_query.)
  def invariant
    self.owner != nil && self.owned_queue_key_query != nil
  end

end
