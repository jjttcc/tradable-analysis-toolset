# Status information used for event monitoring and response
# (Example: end-of-day monitoring process runs periodically and checks if
# EOD processing is currently required (probably within a transaction):
#  # periodically-scheduled EOD job:
#  eod_status = EventStatus.find_by_name("EOD")
#  if eod_status.action_required? then
#    if eod_data_available? then
#      perform_end_processing
#      eod_status.idle!
#      eod_status.save!
#    end
#  end
# )
#!!!!TO-DO: consider adding attribute:
#   event_type: integer
# where event_type is specified here as:
#   enum event_type: {
#     user_triggered:         1,
#     EOD_US_stocks:          2,
#     # etc...
#   }
# IOW, 'event_type' can have the same set of values as
# EventBasedTrigger.triggered_event_type.
# I.e., 'triggered_event_type' would essentially be a foreign key into
# event_statuses.  And, e.g., if event_type == EOD_US_stocks, name would be
# something like: "end-of-day data has become available for US stocks".
#!!!!end-of:TO-DO!!!!!
class EventStatus < ApplicationRecord
  include Contracts::DSL

  public

  enum status: {
    disabled:        0,   # Currently not in use.
    action_required: 1,   # The responsible process must take action ASAP.
    idle:            2,   # No action is currently needed.
  }
end
