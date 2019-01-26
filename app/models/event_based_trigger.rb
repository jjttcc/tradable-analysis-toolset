=begin
triggered_event_type: integer
status: integer
activated: boolean DEFAULT 'f' NOT NULL
=end

#!!!!!!!!!!!!!TO-DO: Move to separate file, use in PeriodicTrigger!!!!!!!!
# 'status'-related operations for *Trigger classes
# Note: Assumes that the class that includes this module has an
# ActiveRecord enum status attribute with the possible states:
#  - available
#  - busy
#  - closed
#  - not_in_use
#!!!!WARNING: As of 2019/01/05, the above could change!!!!!
module TriggerStatus
  include Contracts::DSL
  #!!!!When ready, test/experiment: move enum status {...} to here!!!!

  public  ###  Status setting

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

# Triggers that are activated by an external event
class EventBasedTrigger < ApplicationRecord
  include Contracts::DSL, TriggerStatus

  public

  has_many :analysis_schedules, as: :trigger

  public  ###  Status report

  def ready?
    activated && available?
  end

  private

  enum status: {
    available:   1,   # not activated or not yet invoked
    busy:        2,   # invoked - resulting schedules are being processed
    closed:      3,   # triggered-event was processed, ready for re-use
    not_in_use:  4,   # i.e., it should be ignored
    # etc...
  }

  enum triggered_event_type: {
    user_triggered:         1,
    EOD_US_stocks:          2,
    # etc...
  }

end
