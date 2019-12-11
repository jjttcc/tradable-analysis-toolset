require 'json'
require 'ruby_contracts'
require 'publisher_subscriber'
require 'tat_services_facilities'
require 'tat_util'
require 'logging_facilities'
require 'report_specification'
require 'status_report'

# Facilities for managing the status-reporting service
class ReportManager < PublisherSubscriber
  include Contracts::DSL, TatServicesFacilities, LoggingFacilities, TatUtil

  public

  #####  Access

  # The resulting report
  attr_reader :report

  #####  Basic operations

  # Order the specified reports, by publishing a report request, obtain the
  # results, and feed the resulting reports to each of 'client_methods'.
  pre :args_hash do |hash| hash != nil && hash.is_a?(Hash) end
  pre :valid_keys do |hash|
    hash[:keys] != nil && (hash[:keys].is_a?(Enumerable) ||
        hash[:keys].is_a?(Symbol) || hash[:keys].is_a?(String)) end
  pre :valid_cl_methds do |hash| implies(hash[:client_methods] != nil,
                                   hash[:client_methods].is_a?(Enumerable)) end
  def order_reports(args_hash)
    @report = nil
    @client_methods = args_hash[:client_methods]
    key_list = key_list_from(args_hash[:keys])
    report_specs = ReportSpecification.new(
      type: ReportSpecification::CREATE_TYPE, new_only: false,
      key_list: key_list, response_key: "#{REPORT_KEY_BASE}#{$$}",
      block_msecs: BLOCK_MSECS_DEFAULT, count: args_hash[:count],
      start_time: args_hash[:start_time], end_time: args_hash[:end_time])
    # Request production of the specified reports:
    publish(report_specs.to_json)
    process_report_results(report_specs.response_key)
  end

  # Clean-up/trim the specified (via args_hash[:keys]) report-related log
  # entries.  If args_hash[:count] != nil, it is assumed to be an integer
  # that specifies a minimum number of entries that are to remain after
  # the clean-up.
  pre :args_hash do |hash| hash != nil && hash.is_a?(Hash) end
  pre :valid_keys do |hash|
    hash[:keys] != nil && (hash[:keys].is_a?(Enumerable) ||
        hash[:keys].is_a?(Symbol) || hash[:keys].is_a?(String)) end
  def cleanup_reports(args_hash)
    @report = nil
    key_list = key_list_from(args_hash[:keys])
    remaining_count = args_hash[:count]
    report_specs = ReportSpecification.new(
      type: ReportSpecification::CLEANUP_TYPE, key_list: key_list,
      response_key: "#{REPORT_KEY_BASE}#{$$}", count: remaining_count)
    # Request the cleanup.
    publish(report_specs.to_json)
  end

  # Retrieve information about the log entries for each key in
  # args_hash[:keys] (currently, just the count of log entries for each key)
  pre :args_hash do |hash| hash != nil && hash.is_a?(Hash) end
  pre :valid_keys do |hash|
    hash[:keys] != nil && (hash[:keys].is_a?(Enumerable) ||
        hash[:keys].is_a?(Symbol) || hash[:keys].is_a?(String)) end
  pre :valid_cl_methds do |hash| implies(hash[:client_methods] != nil,
                                   hash[:client_methods].is_a?(Enumerable)) end
  def info(args_hash)
    @report = nil
    @client_methods = args_hash[:client_methods]
    key_list = key_list_from(args_hash[:keys])
    report_specs = ReportSpecification.new(
      type: ReportSpecification::INFO_TYPE, key_list: key_list,
      response_key: "#{REPORT_KEY_BASE}#{$$}")
    # Request the info.
    publish(report_specs.to_json)
    process_report_results(report_specs.response_key)
  end

  protected

  #####  Implementation

  # Wait for and obtain the results, and then feed them to 'client_methods'.
  pre  :no_report do self.report == nil end
  def process_report_results(retrieval_key)
    sleep SHORT_PAUSE
    @report = object(retrieval_key)
    tries = 0
    while @report.nil? && tries < RESPONSE_QUERY_RETRIES do
      sleep RETRY_PAUSE
      @report = object(retrieval_key)
      tries += 1
    end
    if @report.nil? then
      raise "Timeout waiting for report"
    else
      feed_report_to_clients(retrieval_key)
    end
  end

  def feed_report_to_clients(retrieval_key)
    if client_methods != nil && client_methods.count > 0 then
      if report.nil? then
        msg = "#{self.class}.#{__method__}: requested report " +
        "(#{retrieval_key}) was not produced"
        warn(msg)
      else
        client_methods.each do |c|
          c.call(report)
        end
      end
    end
  end

  def key_list_from(keys)
    result = nil
    if keys == ["*"] then
      result = keys   # Special "key" signifying 'all available keys'
    else
      if keys.is_a?(String) || keys.is_a?(Symbol) then
        result = [logging_key_for(keys)]
      else
        result = keys.map { |k| logging_key_for(k) }
      end
    end
    result
  end

  private

  REPORT_KEY_BASE, BLOCK_MSECS_DEFAULT, SHORT_PAUSE =
    'status-report', 2000, 0.15

  RESPONSE_QUERY_RETRIES, RETRY_PAUSE = 100, 0.75

  attr_reader :config, :log_reader, :client_methods, :error_log

  #####  Initialization

  pre  :config_exists do |config| config != nil end
  pre  :good_log do |c, lg| lg != nil && lg.is_a?(MessageLog) end
  post :log do log != nil end
  post :log_reader do log_reader != nil end
  def initialize(config, the_log)
    @log = the_log
    @config = config
    @log_reader = config.log_reader
    @error_log = config.error_log
    initialize_message_brokers(@config)
    initialize_pubsub_broker(@config)
    init_pubsub(default_pubchan: STATUS_REPORTING_CHANNEL,
                default_subchan: REPORT_RESPONSE_CHANNEL)
  end

end
