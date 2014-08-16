# Utilities for interfacing with the MAS client subsystem
module MasClientTools

  public

  def self.new_mas_client(session: nil, user: nil)
    # [Note: If in the future MasClients are cached,
    # session.mas_session_key can be used as a hash key to store/retrieve
    # MasClients.]
    if session
      mas_args = MasClientArgs.new(user: session.user)
    elsif user
      mas_args = MasClientArgs.new(user: user)
    else
      mas_args = MasClientArgs.new
    end
    result = MasClientOptimized.new(mas_args)
  end

  def self.new_mas_client_w_ptypes(period_type_specs)
    # [Note: If in the future MasClients are cached,
    # session.mas_session_key can be used as a hash key to store/retrieve
    # MasClients.]
    if period_type_specs
      mas_args = MasClientArgs.new(period_type_specs: period_type_specs)
    else
      mas_args = MasClientArgs.new
    end
    result = MasClientOptimized.new(mas_args)
  end

end
