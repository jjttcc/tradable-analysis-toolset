require 'service_tokens'

# Utility features that facilitate saving to and reading from a log
module LoggingFacilities
  include Contracts::DSL, ServiceTokens

  public

  #####  Access

  MASTER_LOGGING_KEY = 'master-key'

  # The key used to log reports on information associated with the other
  # keys - i.e., a meta-key for reporting
  def self.master_logging_key
    MASTER_LOGGING_KEY
  end

  # (See 'self.master_logging_key')
  def master_logging_key
    LoggingFacilities::master_logging_key
  end

  # Array: key for each service
  def all_service_keys
    MANAGED_SERVICES
  end

  # The "key" for each service - i.e., '<service>_key' (e.g.:
  #  manage_tradable_tracking_key)
  @@KEY_FOR = {}
  MANAGED_SERVICES.each do |symbol|
    method_name = "#{symbol}_key".to_sym
    # Auto-generated method to produce correct/valid key (i.e.,
    # <service> by method '<service>_key')
    define_method(method_name) do
      symbol
    end
    # @@KEY_FOR - i.e.: Map symbol => "#{symbol}_key"
    @@KEY_FOR[symbol] = symbol.to_s
  end

  # The key, used for logging, for the specified symbol
  post :string_if_exists do |res| implies(res != nil, res.is_a?(String)) end
  def self.logging_key_for(symbol)
    result = @@KEY_FOR[symbol]
    result
  end

  # (See 'self.logging_key_for')
  post :string_if_exists do |res| implies(res != nil, res.is_a?(String)) end
  def logging_key_for(symbol)
    LoggingFacilities::logging_key_for(symbol)
  end

  private

  @@logging_keys = [MASTER_LOGGING_KEY]
  @@logging_keys.concat(MANAGED_SERVICES)

  public

  def self.all_logging_keys
    @@logging_keys
  end

  def all_logging_keys
    LoggingFacilities::all_logging_keys
  end

  # Keys for all active TAT services
  def service_keys
    MANAGED_SERVICES
  end

end
