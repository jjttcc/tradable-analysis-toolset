require 'ruby_contracts'

# Utilities for interfacing with the MAS client subsystem
module MasClientTools
  include Contracts::DSL

  private

  def self.current_mas_args(session, user)
    if session then
      result = MasClientArgs.new(user: session.user)
    elsif user then
      result = MasClientArgs.new(user: user)
    else
      result = MasClientArgs.new
    end
    result
  end

  public

  # A MasClient object - with an active MAS session - for the specified
  # 'session' or 'user'.  If 'next_port': Attempt to
  # create the MasClient with a MAS session
  # connection on the next (with respect to the one previously used) port
  # in the configured list of available ports.  If there are no more ports
  # (all configured ports have been tried), raise a RuntimeError.
  # Exceptions:
  #   - RuntimeError:    No more ports are available.
  #   - MasTimeoutError: Timed-out while communicating with the MAS server.
  def self.mas_client(session: nil, user: nil, next_port: false)
    # [Note: If in the future MasClients are cached,
    # session.mas_session_key can be used as a hash key to store/retrieve
    # MasClients to/from the cache.]
    mas_args = current_mas_args(session, user)
    if next_port then
      if used_ports < number_of_available_ports then
        $log.debug("[self.mas_client] <next_port> - calling shift_to_next_port")
        mas_args.shift_to_next_port
        $log.debug("[self.mas_client] mas_args: #{mas_args.inspect}")
      else
        raise RuntimeError.new("Fatal error: Ran out of available ports.")
      end
    end
    result = MasClientNonblocking.new(mas_args)
    if result.communication_failed then
      if result.last_exception_type == MasTimeoutError then
        # timeout occurred, probably while communicating with the MAS
        # server; try to connect again on the next port:
        result = self.mas_client(session: session, user: user, next_port: true)
      else
        raise result.last_exception
      end
    else
      if false and Rails.configuration.respond_to? :timeout_seconds then
        tsecs = Rails.configuration.timeout_seconds
        if tsecs = tsecs.is_a?(Integer) then
          result.timeout = Rails.configuration.timeout_seconds
        end
      end
      if user != nil && user.mas_session.nil? then
        # nil mas session means that the user was not logged into the MAS
        # server - until MasClient*.new was called.  To reflect this
        # state change, the mas session must be created/saved.
        user.create_mas_session(mas_session_key: result.session_key)
      end
    end
    result
  end

  #!!!!Is this method needed???!!!!
  def self.mas_client_w_ptypes(period_type_specs, next_port: false)
    #!!!Might need to model self.mas_client.
    if ! defined? @@mas_args.nil? then
      if period_type_specs then
        @@mas_args = MasClientArgs.new(period_type_specs: period_type_specs)
      else
        @@mas_args = MasClientArgs.new
      end
    end
    if next_port then
      @@mas_args.shift_to_next_port
    end
    result = MasClientOptimized.new(@@mas_args)
  end

  # Log out the client belonging to 'user' from the MAS server.
  post :no_mas_session do |res, u|
    implies(u != nil, MasSession.find_by_id(user.mas_session.id).nil?) end
  def self.logout_client(user)
    if user != nil && user.mas_session != nil then
      client = self.mas_client(user: user)
      if client.logged_in then
        client.logout
      else
        #!!!!!! Remove this before first production release:
        $log.debug("Fix bug: MAS client was not logged in [#{client.inspect}]")
      end
      user.mas_session.destroy
    end
  end

  def self.number_of_available_ports
    Rails.configuration.mas_ports.count
  end

  # Number of ports that have already been "used".
  def self.used_ports
    result = 0
    #!!!!Note: Might need to find a truly persistent alternative to Rails....:
    if Rails.application.config.respond_to? :current_port_index then
      result = Rails.application.config.current_port_index + 1
    end
    result
  end

end
