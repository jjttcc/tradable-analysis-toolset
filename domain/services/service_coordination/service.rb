require 'tat_util'
require 'tat_services_facilities'

# Abstraction for logic needed for a specific service
module Service
  include Contracts::DSL, TatServicesFacilities, TatUtil

  public

  #####  Access

  attr_reader :service_tag

  #####  Boolean queries

  # Is logging turned on?
  attr_reader :logging_on

  # Is verbose logging enabled?
  def verbose
    false   # (Redefine as needed.)
true  #!!!!!![2019-september-iteration]!!! - temporary/debugging!!!!
  end

  #####  State-changing operations

  # Ensure 'logging_on'.
  post :on do logging_on end
  def turn_on_logging
    @logging_on = true
  end

  # Ensure NOT 'logging_on'.
  post :off do ! logging_on end
  def turn_off_logging
    @logging_on = false
  end

  #####  Basic operations

  # Start the service.
  def execute(args = nil)
    pre_process(args)
    while continue_processing do
      process(args)
    end
    post_process(args)
  end

  protected

  ##### Implementation - utilities

  attr_reader :config, :error_log

  # (Redefined to additionally log the 'msg' if 'logging_on'.)
  def set_message(key, msg, expire_secs = nil, admin = false)
    super(key, msg, expire_secs, admin)
    if logging_on then
      log.send_message(key, msg)
    end
  end

  # If 'logging_on', log the specified set of messages.
  pre :log   do |log_attr| self.log != nil && self.log.is_a?(MessageLog) end
  pre :mhash do |mhash| mhash != nil && mhash.is_a?(Hash) end
  def log_messages(messages_hash)
    if logging_on then
      log.send_messages(messages_hash)
    end
  end

  # If 'logging_on' and 'verbose', log the specified set of messages.
  pre :log   do |log_attr| self.log != nil && self.log.is_a?(MessageLog) end
  pre :mhash do |mhash| mhash != nil && mhash.is_a?(Hash) end
  def log_verbose_messages(messages_hash)
    if verbose && logging_on then
      log.send_messages(messages_hash)
    end
  end

  ##### Hook methods

  def continue_processing
    true  # Redefine if needed.
  end

  # Perform the main processing.
  def process(args = nil)
    # Null operation - Redefine if needed.
  end

  # Perform any needed pre-processing.
  def pre_process(args = nil)
    # Null operation - Redefine if needed.
  end

  def post_orocess(args = nil)
    # Null operation - Redefine if needed.
  end

  #####  Invariant

  def invariant
    ! (config.nil? || log.nil? || error_log.nil?)
  end

end
