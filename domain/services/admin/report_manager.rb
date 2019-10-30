require 'json'
require 'concurrent'
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
  # Is 'report' empty?
#!!!!!!OLD:
  attr_reader :empty_report

  #####  Basic operations

  # Order the specified reports, by publishing a report request, obtain the
  # results, and feed the resulting reports to each of 'client_methods'.
  pre :valid_report_keys do |keys| keys != nil &&
    (keys.is_a?(Enumerable) || keys.is_a?(Symbol) || keys.is_a?(String)) end
  pre :valid_rcli do |k, cli| implies(cli != nil, cli.is_a?(Enumerable)) end
  def order_reports(keys, cl_methods = nil)
    @report = nil
    @client_methods = cl_methods
    key_list = key_list_from(keys)
    report_specs = ReportSpecification.new(type: :create, new_only: false,
        key_list: key_list, response_key: "#{REPORT_KEY_BASE}#{$$}",
        block_msecs: BLOCK_MSECS_DEFAULT)
puts "check these report specs:\n#{report_specs.inspect}"
    # Request production of the specified reports:
    publish(report_specs.to_json)
    process_report_results(report_specs.response_key)
  end

  # Clean-up/trim the specified (via 'keys') report-related log entries.
  # If 'remaining_count' != nil, it is assumed to be an integer that
  # specifies a minimum number of entries that are to remain after the
  # clean-up.
  pre :valid_report_keys do |keys| keys != nil &&
    (keys.is_a?(Enumerable) || keys.is_a?(Symbol) || keys.is_a?(String)) end
  def cleanup_reports(keys, remaining_count = nil)
    @report = nil
    key_list = key_list_from(keys)
    report_specs = ReportSpecification.new(type: :cleanup, key_list: key_list,
        response_key: "#{REPORT_KEY_BASE}#{$$}", count: remaining_count)
puts "check these report specs:\n#{report_specs.inspect}"
    # Request the cleanup.
    publish(report_specs.to_json)
#!!!    process_report_results(report_specs.response_key)
  end

  protected

  #####  Implementation

  # Wait for and obtain the results, and then feed them to 'client_methods'.
  pre  :no_report do self.report == nil end
  def process_report_results(retrieval_key)
    sleep SHORT_PAUSE
    @report = object(retrieval_key)
puts "prr:A = report: #{@report.inspect}"
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

  # Wait for and obtain the results, and then feed them to 'client_methods'.
  pre  :no_report do self.report == nil end
#!!!  post :rep_nil_iff_empty do self.empty_report == self.report.nil? end
  def old____process_report_results(retrieval_key)
    @empty_report = false
    subscribe_task = Concurrent::ScheduledTask.new(0) do
      subscribe_once do
        if @report == nil then
          @report = object(retrieval_key)
        end
        if @report == nil then
          @empty_report = true
puts "prr - empty report"
        end
puts "prr:i = report: #{@report.inspect}"
      end
    end
    subscribe_task.execute
    # Wait for 'subscribe_task' to do its work.
    sleep SHORT_PAUSE
puts "prr:A = report: #{@report}"
    if self.empty_report then
puts "prr:B = report: #{@report}"
      # Subscription notification received, but report is empty.
      warn("empty report (#{retrieval_key}) received.")
puts "prr:C"
    else
puts "prr:D = report: #{@report.inspect}"
      if report.nil? then
        @report = object(retrieval_key)
puts "prr:E = report: #{@report.inspect}"
      end
      if report.nil? then
puts "prr:F = report: #{@report}"
        # Sleep, then try again.
        sleep RESPONSE_DEADLINE_SECS
        if report.nil? then
          # 'subscribe_task' subscription notification failed - do the work:
          @report = object(retrieval_key)
puts "prr:G = report: #{@report.inspect}"
        end
      end
puts "prr:H = report: #{@report}"
      feed_report_to_clients(retrieval_key)
    end
puts "prr:I = report: #{@report.inspect}"
  end

  def feed_report_to_clients(retrieval_key)
puts "frtc:A (retkey: #{retrieval_key}), report: #{@report}"
puts "frtc:A[i] report: #{report}"
    if client_methods != nil && client_methods.count > 0 then
      if report.nil? then
puts "frtc:B"
        msg = "#{self.class}.#{__method__}: requested report " +
        "(#{retrieval_key}) was not produced"
        warn(msg)
      else
puts "frtc:C"
        client_methods.each do |c|
          c.call(report)
        end
      end
puts "frtc:D"
    end
puts "frtc:E"
  end

  def key_list_from(keys)
    result = nil
    if keys.is_a?(String) || keys.is_a?(Symbol) then
      result = [logging_key_for(keys)]
    else
      result = keys.map { |k| logging_key_for(k) }
    end
    result
  end

  private

  REPORT_KEY_BASE, BLOCK_MSECS_DEFAULT, SHORT_PAUSE =
    'status-report', 2000, 0.15

  #!!!!!OLD:
  RESPONSE_DEADLINE_SECS = 3.65

  RESPONSE_QUERY_RETRIES, RETRY_PAUSE = 50, 0.75

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
