require 'ruby_contracts'

# Methods, state, logic, etc. used for querying and managing a service's
# run-state (which can be 'running', 'suspended', or 'terminated')
module ServiceStateFacilities
  include Contracts::DSL
  include ServiceTokens, TatServicesConstants

  public

  attr_reader :run_state

  private

  ##### Messaging-related constants, settings

  SERVICE_SUSPEND               = 'suspend'
  SERVICE_TERMINATE             = 'terminate'
  SERVICE_RESUME                = 'resume'
  SERVICE_SUSPENDED             = :suspended
  SERVICE_TERMINATED            = :terminated
  SERVICE_RUNNING               = :running
  STATE_FOR_CMD                 = {
    SERVICE_SUSPEND         => SERVICE_SUSPENDED,
    SERVICE_TERMINATE       => SERVICE_TERMINATED,
    SERVICE_RESUME          => SERVICE_RUNNING,
  }

  ######## Service-control commands, states, and utilities ########

  # Is the service suspended?
  pre  :invariant do invariant end
  post :invariant do invariant end
  def suspended?
    run_state == SERVICE_SUSPENDED
  end

  # Is the service terminated?
  pre  :invariant do invariant end
  post :invariant do invariant end
  def terminated?
    run_state == SERVICE_TERMINATED
  end

  # Is the service running?
  pre  :invariant do invariant end
  post :invariant do invariant end
  def running?
    run_state == SERVICE_RUNNING
  end

  # Is 'service' alive?
  pre :valid do |service| ServiceTokens::SERVICE_EXISTS[service] end
  def is_alive?(service)
    method_name = "#{service}_run_state"
    status = method(method_name).call
    result = !! (status =~ /^#{SERVICE_RUNNING}/ ||
                  status =~ /^#{SERVICE_SUSPENDED}/)  # (i.e., as boolean)
    result
  end

  # query: ordered_<service>_run_state (last ordered run-state for <service>)
  MANAGED_SERVICES.each do |symbol|
    method_name = "ordered_#{symbol}_run_state".to_sym
    define_method(method_name) do
      command = retrieved_message(CONTROL_KEY_FOR[symbol], true)
      STATE_FOR_CMD[command]
    end
  end

  # "order_<service>_<run-state>" commands
  MANAGED_SERVICES.each do |symbol|
    {
      :suspension  => SERVICE_SUSPEND,
      :resumption  => SERVICE_RESUME,
      :termination => SERVICE_TERMINATE
    }.each do |command, state|
      define_method("order_#{symbol}_#{command}".to_sym) do
        set_message(CONTROL_KEY_FOR[symbol], state,
            DEFAULT_ADMIN_EXPIRATION_SECONDS, true)
      end
    end
  end

  # "<service>_<run-state>?" queries - e.g., <service>_suspended?, ...
  MANAGED_SERVICES.each do |symbol|
    method_name = "#{symbol}_run_state".to_sym
    define_method(method_name) do
      result = retrieved_message(STATUS_KEY_FOR[symbol], true)
      result
    end
    # <service>_suspended?, <service>_running?, ... queries
    [
      SERVICE_SUSPENDED, SERVICE_RUNNING, :unresponsive, SERVICE_TERMINATED
    ].each do |state|
      state_query_name = "#{symbol}_#{state}?".to_sym
      define_method(state_query_name) do
        result = false
        status = method(method_name).call
        if status.nil? || status.empty? then
          if state == :unresponsive then
            result = true
          end
        else
          result = state.to_s == status[0..state.length-1]
        end
        result
      end
    end
  end

  # send_<service>_run_state reporting
  MANAGED_SERVICES.each do |symbol|
    m_name = "send_#{symbol}_run_state".to_sym
    key = STATUS_KEY_FOR[symbol]
    define_method(m_name) do |exp = RUN_STATE_EXPIRATION_SECONDS|
      begin
        value_arg = "#{run_state}@#{Time.now.utc}"
        set_message(key, value_arg, exp, true)
      rescue StandardError => e
        error_log.warn("exception in #{__method__}: #{e}")
      end
    end
  end

  # delete_<service>_order (delete last ordered run-state for <service>)
  MANAGED_SERVICES.each do |symbol|
    method_name = "delete_#{symbol}_order".to_sym
    define_method(method_name) do
      delete_object(CONTROL_KEY_FOR[symbol])
    end
  end

  ##### Convenience methods

  # Retrieve any pending external state-management commands and enforce a
  # response by changing the internal state - i.e., @run_state.
  pre  :invariant do invariant end
  post :invariant do invariant end
  def update_run_state
    if @ordered_state_query.nil? then
      @ordered_state_query = "ordered_#{@service_tag}_run_state".to_sym
    end
    new_state = send(@ordered_state_query)
    if new_state != nil && new_state != run_state then
      @run_state = new_state
      if terminated? then
        if @delete_order_command.nil? then
          @delete_order_command = "delete_#{@service_tag}_order".to_sym
        end
        # (Make sure the order doesn't "linger" after termination.)
        send(@delete_order_command)
      end
    end
  end

  # Update the 'run_state' ('update_run_state') to ensure "our" internal
  # run-state is up-to-date and report that state via the messaging broker.
  pre  :invariant do invariant end
  post :invariant do invariant end
  def report_run_state
    update_run_state
    if @state_report_command.nil? then
      @state_report_command = "send_#{@service_tag}_run_state".to_sym
    end
    send(@state_report_command)
  end

  #####  Class/module invariant

  def invariant
    (run_state == SERVICE_SUSPENDED || run_state == SERVICE_TERMINATED ||
      run_state == SERVICE_RUNNING) &&
    (@service_tag != nil && ! @service_tag.empty?)
  end

end
