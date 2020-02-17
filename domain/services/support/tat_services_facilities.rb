require 'concurrent'
require 'ruby_contracts'
require 'stderr_error_log'
require 'tat_services_constants'
require 'messaging_facilities'
require 'service_tokens'

# Constants and other "facilities" used by/for the TAT services
module TatServicesFacilities
  include Contracts::DSL
  include TatServicesConstants, MessagingFacilities, ServiceTokens

  public

  attr_reader :log

  # Tag identifying "this" service
  post :result_valid do |result|
    implies(result != nil, SERVICE_EXISTS[result]) end
  def service_tag
    nil   # Redefine, if appropriate.
  end

  private

  if $is_production_run.nil? then
    raise "Fatal: '$is_production_run' is nil or not defined."
  end

  ##### messaging-related constants, settings

###!!!!!move this???:::!!!!
  STATUS_KEY, STATUS_VALUE, STATUS_EXPIRE = :status, :value, :expire

###!!!!!!!!Should these 2 constants be moved?:
  EXCH_MONITOR_NEXT_CLOSE_SETTINGS   = {
    STATUS_KEY    => EXCHANGE_CLOSE_TIME_KEY,
    # default:
    STATUS_VALUE  => 'no markets open today',
    STATUS_EXPIRE => EXMON_PAUSE_SECONDS + 1
  }
  EXCH_MONITOR_OPEN_MARKET_SETTINGS = {
    STATUS_KEY    => OPEN_EXCHANGES_KEY,
    STATUS_VALUE  => '',
    STATUS_EXPIRE => nil
  }

  ##### General messaging utilities #####

  # Send a "generic" application message ('msg'), using 'key', with
  # default expiration TTL.
  def send_generic_message(key, msg, exp = DEFAULT_APP_EXPIRATION_SECONDS)
    set_message(key, msg, exp)
  end

  # Delete the message with the specified key.
  def delete_message(key)
    delete_object(key)
  end

  ##### Generic service/process control utilities #####

  begin

    PROCTERM = :terminate

    # Order process termination via key "#{keybase}:#{PROCTERM}".
    # If acknowledgement_timeout > 0, wait (block) until the receiver of the
    # termination order has acknowledged (by clearing the associated value
    # [e.g., via clear_order(keybase)]) the termination order, or until
    # acknowledgement_timeout seconds elapses - whichever happens first.
    # Otherwise (acknowledgement_timeout <= 0), do not wait for confirmation.
    def order_termination(keybase, acknowledgement_timeout = MSG_ACK_TIMEOUT)
      key = "#{keybase}:#{PROCTERM}"
      send_generic_message(key, true)
      if acknowledgement_timeout > 0 then
        sleep 1
        secs_passed = 1
        until retrieved_message(key) != true.to_s ||
                secs_passed >= acknowledgement_timeout
          sleep 1
          secs_passed += 1
        end
      end
    end

    # Has process termination been ordered via key "#{keybase}:#{PROCTERM}"?
    # If 'clear', ensure the order is cleared (i.e., the next call to
    # 'termination_ordered' will return false) before returning.
    def termination_ordered(keybase, clear = false)
      value = retrieved_message("#{keybase}:#{PROCTERM}")
      result = value == 'true'
      if clear then
        clear_order(keybase)
      end
      result
    end

    # Clear the last order sent (e.g., by calling 'order_termination') via
    # key "#{keybase}:#{PROCTERM}"
    def clear_order(keybase)
      send_generic_message("#{keybase}:#{PROCTERM}", nil)
    end

  end

  ######## Utilities

  # Evaluation (Array) of the Hash 'settings_hash'
  def eval_settings(settings_hash, replacement_value = nil,
                    replacement_expiration_seconds = nil)
    _, value, expire = 0, 1, 2
    result = [settings_hash[STATUS_KEY], settings_hash[STATUS_VALUE],
              settings_hash[STATUS_EXPIRE]]
    if replacement_value != nil then
      result[value] = replacement_value
    end
    if replacement_expiration_seconds != nil then
      result[expire] = replacement_expiration_seconds
    end
    # If the 'value' is a lambda/Proc, use its result:
    if result[value].respond_to?(:call) then
      result[value] = result[value].call
    end
    # If the expiration period is nil, no expiration is to be used:
    if result[expire].nil? then
      result.pop
    end
    result
  end

  # Create the timer (task) responsible for periodic reporting of 'run_state'.
  post :task_exists do @status_task != nil end
  def create_status_report_timer(status_manager:,
            period_seconds: RUN_STATE_EXPIRATION_SECONDS - 1)
    @status_task = Concurrent::TimerTask.new(
          execution_interval: period_seconds) do |task|
      begin
        if status_manager != nil then
          status_manager.report_run_state
        end
      rescue StandardError => e
        error_log.warn("exception in #{__method__}: #{e}")
      end
    end
  end

  # Timer task configured to run method 'mthd' every 'secs' seconds
  post :task_exists do |result| result != nil end
  def periodic_task(mthd:, secs:)
    result = Concurrent::TimerTask.new(
          execution_interval: secs) do |task|
      begin
        mthd.call
      rescue StandardError => e
        error_log.warn("exception in #{__method__}: #{e}")
      end
    end
  end

  ######## Logging

  LOGGING_TAGS = [:info, :debug, :test, :warn, :error, :fatal, :unknown]
  OPTIONAL_LOGGING_TAGS = [:info, :debug]

  # Object used for error logging
  def error_log
    # (Default to self.log - redefine if separate 'log' and 'error_log'
    # objects are needed.)
    self.log
  end

  # Log the specified error (or warning, info, ...) message.
  pre :level_valid do |_, level|
    LOGGING_TAGS.include?(level.to_sym) end
  pre :msg_exists do |msg| msg != nil end
  def log_error(msg, level = 'warn')
    error_log.method(level.to_sym).call(msg)
  end

  begin

    is_void = {}
    if $is_production_run then
      OPTIONAL_LOGGING_TAGS.each do |sym|
        is_void[sym] = true
      end
    end
    # Logging with category: info, debug, warn, ...:
    LOGGING_TAGS.each do |m_name|
      if is_void[m_name] then
        # (Define as a no-op.)
        define_method(m_name) {|dummy_arg| }
      else
        define_method(m_name) do |msg|
          log_error(msg, m_name)
        end
      end
    end

  end

end
