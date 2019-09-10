require 'tat_util'
require 'tat_services_facilities'

# Abstraction for logic needed for a specific service
module Service
  include Contracts::DSL, TatServicesFacilities, TatUtil

  public  ###  Access

  attr_reader :service_tag

  public  ###  Basic operations

  # Start the service.
  def execute(args = nil)
  end

end
