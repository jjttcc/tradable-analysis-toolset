# Utilities for interfacing with the MAS client subsystem
module MasClientTools

  public

  def self.mas_client(session: nil, user: nil)
    # [Note: If in the future MasClients are cached,
    # session.mas_session_key can be used as a hash key to store/retrieve
    # MasClients to/from the cache.]
    if session
      mas_args = MasClientArgs.new(user: session.user)
    elsif user
      mas_args = MasClientArgs.new(user: user)
    else
      mas_args = MasClientArgs.new
    end
    result = MasClientOptimized.new(mas_args)
    if user != nil && user.mas_session.nil?
      # nil mas session means that the user was not logged into the MAS
      # server - until MasClientOptimized.new was called.  To reflect this
      # state change, the mas session must be created/saved.
      user.create_mas_session(mas_session_key: result.session_key)
    end
    result
  end

  def self.mas_client_w_ptypes(period_type_specs)
    if period_type_specs
      mas_args = MasClientArgs.new(period_type_specs: period_type_specs)
    else
      mas_args = MasClientArgs.new
    end
    result = MasClientOptimized.new(mas_args)
  end

  # Log out the client belonging to 'user' from the MAS server.
  def self.logout_client(user)
    if user != nil && user.mas_session != nil
      client = self.mas_client(user: user)
      if client.logged_in
        client.logout
      else
        #!!!!!! Remove this before first production release:
        raise "Fix bug: client was not logged in [#{client.inspect}]"
      end
    end
  end

end
