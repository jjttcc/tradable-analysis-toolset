# Encapsulation of services intercommunications from the point-of-view of
# the "EOD-event-triggering" service
class EODEventInterCommunications
  include Contracts::DSL
  include TatServicesFacilities, ServiceStateFacilities

  private

  #####  Implementation

  attr_accessor :error_log

  def initialize(owner)
    # For 'debug', 'error', ...:
    self.error_log = owner.send(:error_log)
    initialize_message_brokers(owner.send(:config))
    @run_state = SERVICE_RUNNING
    @service_tag = EOD_EVENT_TRIGGERING
  end

end
