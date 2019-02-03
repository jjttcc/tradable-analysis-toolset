# !!!!!(Need class description)
class TriggerHandler
  include Contracts::DSL

  public

  attr_accessor :trigger, :exception

  # Reported reason for last transaction failure
  attr_reader :exception

  ###  Status report

  # Did the last lock attempt fail?
  def lock_failed?
    @lock_failed
  end

  # Did an error occur causing a transaction failure?
  post :exception_if_true do |result| implies(result, ! exception.nil?) end
  def error?
    @error
  end

  ###  Basic operations

  # Attempt to lock 'trigger', claim it (i.e., trigger.claim!), invoke the
  # given block on it, and then release (trigger.release!) it.  If the lock
  # fails, do not invoke the block and ensure 'lock_failed?'.  If an
  # exception occurs that is not related to lock failure, 'error?' is
  # true and 'exception' holds the resulting rescued exception.
  pre  :trigger_exists do trigger != nil end
  pre  :trigger_available do trigger.available? end
  post :closed do lock_failed? || trigger.closed? end
  def claim_and_execute
    @lock_failed = true
    @error = false
    trigger.transaction(joinable: false, requires_new: true) do
      trigger.claim
      yield(trigger)
      trigger.release
      trigger.save!
      @lock_failed = false
      $log.debug("(claim_and_execute finished [trigger: #{trigger.inspect}])")
    end
  rescue ActiveRecord::StaleObjectError => e
    $log.info("optimistic lock failed in #{__method__} for " +
               "#{e.inspect} -\nskipping (#{e})")
  rescue ActiveRecord::StatementInvalid => e
    $log.error("StatementInvalid exception in #{__method__} for " +
               "#{e} (#{e.inspect})\n[need DB recovery plan]")
    @exception = e  # Ensure 'error?' postcondition.
    @error = true
  rescue ActiveRecord::ActiveRecordError => e
    $log.error("[#{self.class}.#{__method__}] transaction failed: " +
               "#{e} (#{e.inspect})\n[need DB recovery plan]")
    @exception = e
    @error = true
  end

  # Attempt to lock 'trigger' and "reset" it.
  # If the lock fails, ensure 'lock_failed?'.
  # If an exception occurs that is not related to lock failure, 'error?' is
  # true and 'exception' holds the resulting rescued exception.
  pre  :trigger_exists do trigger != nil end
  pre  :closed_or_unused do trigger.closed? || trigger.not_in_use? end
  post :available do lock_failed? || trigger.available? end
  def reset
    @lock_failed = true
    @error = false
    trigger.transaction(joinable: false, requires_new: true) do
      trigger.reset
      trigger.save!
      @lock_failed = false
      $log.debug("(reset finished [trigger: #{trigger.inspect}])")
    end
  rescue ActiveRecord::StaleObjectError => e
    $log.info("optimistic lock failed in #{__method__} for " +
               "#{e.inspect} -\nskipping (#{e})")
  rescue ActiveRecord::StatementInvalid => e
    $log.error("StatementInvalid exception in #{__method__} for " +
               "#{e} (#{e.inspect})\n[need DB recovery plan]")
    @exception = e  # Ensure 'error?' postcondition.
    @error = true
  rescue ActiveRecord::ActiveRecordError => e
    $log.error("[#{self.class}.#{__method__}] transaction failed: " +
               "#{e} (#{e.inspect})\n[need DB recovery plan]")
    @exception = e
    @error = true
  end

  private

  def initialize(trigger = nil)
    self.trigger = trigger
    @lock_failed = false
  end

end
