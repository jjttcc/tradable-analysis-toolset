# 'status'-related operations for *Trigger classes
# Note: Assumes that the class that includes this module has an
# ActiveRecord enum status attribute with the possible states:
#  - available
#  - busy
#  - closed
#  - not_in_use
module TriggerStatus
  include Contracts::DSL

  public

  #####  State-changing operations

  # Claim ownership of 'self' and set 'status' to 'available'.
  # Should be called within a transaction.
  pre  :available do available? end
  post :busy do busy? end
  def claim
    busy!
  end

  # Set 'status' to 'available'.
  pre  :closed_or_unused do closed? || not_in_use? end
  post :available do available? end
  def reset
    available!
  end

  # Release ownership of 'self' and set 'status' to 'closed'.
  # Should be called within a transaction.
  pre  :busy do busy? end
  post :closed do closed? end
  def release
    closed!
  end

  # Make 'self' unavailable - i.e., set 'status' to 'not_in_use'.
  # Should be called within a transaction.
  pre  :not_busy do ! busy? end
  post :not_in_use do not_in_use? end
  def disable
    not_in_use!
  end

  def ready?
    $log.debug("ABSTRACT METHOD: #{self.class} #{__method__}")
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

end
