require 'service_manager'

# ServiceManagers responsible for managing the messaging broker - starting it
# (if appropriate and if it needs starting) and making sure it stays
# up/available
class MessageBrokerManager < ServiceManager

  private  ### Hook method implementations

  def is_alive?(tag)
$stderr.puts "[MessageBrokerManager] calling ...is_alive...";$stderr.flush
    result = broker.is_alive? && admin_broker.is_alive?
$stderr.puts "[MessageBrokerManager] = RESULT: #{result}";$stderr.flush
    result
  rescue
    false
  end

  def start_service
    if ! is_alive?(tag) then
      # The user and admin message brokers are expected to be already running:
      raise "Fatal error: one or both message brokers are not available."
    end
  end

  def default_tag
    :message_broker
  end

end
