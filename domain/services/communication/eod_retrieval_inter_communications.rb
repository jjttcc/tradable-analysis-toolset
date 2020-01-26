
# Encapsulation of services intercommunications from the POV of EOD
# retrieval
class EODRetrievalInterCommunications
  public

  #####  Access

  attr_reader :subscription_channel, :publication_channel

#!!!!TO-DO: search for and address: #!!!!!!message-broker communication!!!!!!
#!!!!TO-DO: look for other comms not yet marked/commented, and address!!!!!!!

  # Symbols still in "our" queue (pending) and thus needing processing
  # post :our_key_set do our_queue_key == owner.send(owned_queue_key_query) end
  # If supplied, 'owner' will be used as the target of the queueing methods
  # instead of self.owner.
  def pending_symbols(owner = self.owner)
    # Obtain the key to the pending-symbols queue from our "owner":
    @our_queue_key = owner.send(owned_queue_key_query)
    result = owner.queue_contents(our_queue_key)
    owner.send(:debug, "#{self.class}.#{__method__}, key: "\
               "#{our_queue_key} returning #{result}")
    result
  end

  #####  Message-broker state-changing operations

#!!!!!I think this method will go away:
  def subscribe_to_eod_notification(owner = self.owner)
    owner.subscribe_once do
      owner.send(:debug, "owner.subscribe_once invoked [#{owner}]")
      owner.eod_check_key = owner.last_message
    end
  end

  # Traverse "our" symbols queue and for each symbol, s, in the queue for
  # which the associated data has been fully updated, move s to the queue
  # identified by 'target_queue_key' - that is:
  #   While we've not traversed the entire queue: for the current head, h:
  #     o if h is now up to date (yield(h) is true), move h from "our"
  #       queue to the tail of the target ('target_queue_key') queue
  #     o else rotate "our" queue so that h becomes the tail of the queue
  #       and the former second element becomes the head.
  # If supplied, the last argument, 'owner', will be used as the target
  # of the queueing methods instead of self.owner.
  def process_symbols_queue(target_queue_key, owner = self.owner)
owner.send(:debug, "1 [tqk: #{target_queue_key}")
    if our_queue_key.nil? then
      @our_queue_key = owner.send(owned_queue_key_query)
    end
    count = owner.queue_count(our_queue_key)
    (0 .. count - 1).each do |i|
      head = owner.queue_head(our_queue_key)
      if yield(head) then   # If "we" are finished with 'head'
        # Move the head of "our" queue to the target queue tail (if
        # possible, as an atomic operation).
        owner.move_head_to_tail(our_queue_key, target_queue_key)
      else    # (Not yet finished with 'head')
        # (Move the head of "our" queue to the tail.)
        owner.rotate_queue(our_queue_key)
      end
    end
  end

  # Notify all who are interested that the EOD-retrieval action has completed.
  # If supplied, the last argument, 'owner', will be used as the target
  # of the called methods instead of self.owner.
  def notify_of_completion(notification_key, owner = self.owner)
    owner.send(:send_eod_retrieval_completed, notification_key)
  end

  # Notify all who are interested that the EOD-retrieval action timed out.
  # If supplied, the last argument, 'owner', will be used as the target
  # of the called methods instead of self.owner.
  def notify_of_timeout(notification_key, msg, owner = self.owner)
    owner.send(:send_eod_retrieval_timed_out, notification_key, msg)
  end

  # Notify, via publication, all who are interested that a (possibly
  # incomplete) EOD-data update has occurred.  If 'enqueue_key', then call
  # 'enqueue_eod_ready_key' with 'notification_key' as well.  If supplied,
  # the third argument, 'owner', will be used instead of self.owner.
  def notify_of_update(notification_key, enqueue_key = false,
                       owner = self.owner)
    owner.publish notification_key
    owner.send(:debug, "published '#{notification_key}'")
    if enqueue_key then
      owner.send(:enqueue_eod_ready_key, notification_key)
    end
  end

  protected

  attr_accessor :owner
  attr_accessor :owned_queue_key_query
  attr_reader   :our_queue_key

  def initialize(owner:, my_key_query:)
    self.owner = owner
    self.owned_queue_key_query = my_key_query
    @subscription_channel = TatServicesConstants::EOD_CHECK_CHANNEL
    @publication_channel = TatServicesConstants::EOD_DATA_CHANNEL
  end

end
