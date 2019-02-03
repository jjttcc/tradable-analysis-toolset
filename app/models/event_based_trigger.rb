=begin
triggered_event_type: integer
status: integer
activated: boolean DEFAULT 'f' NOT NULL
=end

# Triggers that are activated by an external event
class EventBasedTrigger < ApplicationRecord
  include Contracts::DSL, TriggerStatus

  public

  has_many :analysis_schedules, as: :trigger

  public ###  Access

  # All exchanges associated 'symbols'
  post :exists do |result| ! result.nil? end
  def exchanges
  end

  # All tradable symbols configured within the hierarchy contained in
  # the 'analysis_schedules'
  post :exists do |result| ! result.nil? end
  def symbols
    result = []
    analysis_schedules.each do |s|
      result.concat(s.symbols)
    end
    result
  end

  public  ###  Status report

  pre :bad do false end
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
