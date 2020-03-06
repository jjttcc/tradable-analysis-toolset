require 'service_state_facilities'

# Encapsulation of services intercommunications from the POV of
# status reporting
class StatusReportingInterCommunications
  include Contracts::DSL
  include MessagingFacilities
  include ServiceStateFacilities

  public

  #####  Access

  protected

  attr_accessor :error_log

  def initialize(owner)
    # For 'debug', 'error', ...:
    self.error_log = owner.send(:error_log)
    initialize_message_brokers(owner.send(:config))
    @run_state = SERVICE_RUNNING
    @service_tag = STATUS_REPORTING
  end

end
