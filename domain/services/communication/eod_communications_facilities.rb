
# Facilities used by the end-of-day-data-retrieval service to communicate
# with other services
module EODCommunicationsFacilities
  include TatServicesConstants, MessagingFacilities

  ##### Queries

  public

  # new key for symbol set associated with eod-data-ready notifications
  def new_eod_data_ready_key
    EOD_DATA_KEY_BASE + next_key_integer.to_s
  end

  # The contents, in order, of the "EOD-check" key queue
  def eod_check_keys
    queue_contents(EOD_CHECK_QUEUE)
  end

  # The contents, in order, of the "EOD-data-ready" key queue
  def eod_ready_keys
    queue_contents(EOD_READY_QUEUE)
  end

  # Does the "EOD-check" key queue contain 'value'?
  def eod_check_queue_contains(value)
    queue_contains(EOD_CHECK_QUEUE, value)
  end

  # Does the "EOD-data-ready" key queue contain 'value'?
  def eod_ready_queue_contains(value)
    queue_contains(EOD_READY_QUEUE, value)
  end

  # The next EOD check key-value - i.e., the value currently at the
  # head of the "EOD-check" key queue.  nil if the queue is empty.
  def next_eod_check_key
    queue_head(EOD_CHECK_QUEUE)
  end

  # The next EOD data-ready key-value - i.e., the value currently at the
  # head of the "EOD-data-ready" key queue.  nil if the queue is empty.
  def next_eod_ready_key
    queue_head(EOD_READY_QUEUE)
  end


  #####  Message-broker queue modification

  # Add the specified EOD data-ready key-value to the "EOD-data-ready" key
  # queue.
  def enqueue_eod_ready_key(key_value)
    queue_messages(EOD_READY_QUEUE, key_value, DEFAULT_EXPIRATION_SECONDS)
  end

  # Remove the head (i.e., next_eod_check_key) of the "EOD-check" key queue.
  # Return the removed-value/former-head - nil if the queue is empty or
  # does not exist.
  def dequeue_eod_check_key
    remove_next_from_queue(EOD_CHECK_QUEUE)
  end

  # Remove the head (i.e., next_eod_ready_key) of the "EOD-data-ready" key
  # queue.
  # Return the removed-value/former-head.
###!!!!Note: This method might not belong in this module:
  def dequeue_eod_ready_key
    remove_next_from_queue(EOD_READY_QUEUE)
  end

  # Remove all occurrences of 'value' from the "EOD-check" key queue.
  # Return the number of removed elements.
  def remove_from_eod_check_queue(value)
    remove_from_queue(EOD_CHECK_QUEUE, value)
  end

  # Remove all occurrences of 'value' from the "EOD-data-ready" key queue.
  # Return the number of removed elements.
###!!!!Note: This method might not belong in this module:
  def remove_from_eod_ready_queue(value)
    remove_from_queue(EOD_READY_QUEUE, value)
  end

  begin

    private

    #####  Implementation

    EOD_FINISHED_SUFFIX = :finished
    EOD_COMPLETED_STATUS = ""
    EOD_TIMED_OUT_STATUS = :timed_out

    def eod_completion_key(keybase)
      "#{keybase}:#{EOD_FINISHED_SUFFIX}"
    end

    # Send status: EOD-data-retrieval completed successfully.
    def send_eod_retrieval_completed(key)
      completion_key = eod_completion_key(key)
      set_message(completion_key, EOD_COMPLETED_STATUS)
    end

    # Send status: EOD-data-retrieval ended without completing due to
    # time-out, with ":msg" (if not empty) appended.
    def send_eod_retrieval_timed_out(key, msg)
      completion_key = eod_completion_key(key)
      status_msg = EOD_TIMED_OUT_STATUS
      if msg != nil && ! msg.empty? then
        status_msg = "#{status_msg}:#{msg}"
      end
      set_message(completion_key, status_msg)
    end

    # Status reported by the EOD-data-retrieval service
    def eod_retrieval_completion_status(key)
      completion_key = eod_completion_key(key)
      result = retrieved_message(completion_key)
    end

    # Does the value returned by 'eod_retrieval_completion_status' indicate
    # that the retrieval completed successfully?
    def eod_retrieval_completed?(value)
      value == EOD_COMPLETED_STATUS
    end

    # Does the value returned by 'eod_retrieval_completion_status' indicate
    # that the retrieval timed-out before completion?
    def eod_retrieval_timed_out?(value)
      value =~ /^#{EOD_TIMED_OUT_STATUS}/
    end

  end

end
