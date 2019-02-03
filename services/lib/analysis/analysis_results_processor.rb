require 'concurrent'

# Processing of the results (AnalysisProfileRun, AnalysisRun,
# AnalysisEvent, etc. persistent objects) from a scheduled analysis run
# (i.e., 'request_analysis' calls to the MAS server) - involves sending
# configured notifications about the results and recording the resulting
# notification status (sent, failed, ...) in the database.
class AnalysisResultsProcessor
  include Contracts::DSL

  public  ###  Access

  # Known types of notification media
  # Hash table: type-name => enum-value
  def medium_types
    if @medium_types.nil? then
      @medium_types = NotificationAddress.medium_types
    end
    @medium_types
  end

  # A new notifier for 'o' of the right type, based on "o"'s medium_type
  pre  :o_exists do |o| ! o.nil? end
  post :result_exists do |result| ! result.nil? end
  def notifier_for(o)
    key = medium_types[o.medium_type]
    result = @notifier_for_mediumtype[key]
    result
  end

  public  ###  Basic operations
#!!!!!!!!REMINDER!!!!!!!!!: Ensure IS_TAT_SERVICE env. var. is defined!!!!!!

  # Retrieve each AnalysisProfileRun whose notifications need initializing
  # and attempt to create and initialize its required Notification objects.
  def create_notifications
    pruns = AnalysisProfileRun.not_initialized
$log.debug("create_notifications: NEW Implementation")
    pool = Concurrent::FixedThreadPool.new(CREATE_NOTIF_THREAD_COUNT)
$log.debug("creating notifs for #{pruns.count} pruns")
    pruns.each do |r|
      pool.post do
        r.create_notifications
#!!!!publish: r has been initialized.
      end
    end
    pool.shutdown
pool.wait_for_termination
#!!!![should we block? - probably not]:    pool.wait_for_termination
  end

  # Retrieve each AnalysisProfileRun whose notifications need
  # to be sent and attempt to send them.
  def perform_notifications
    pruns = AnalysisProfileRun.initialized +
      AnalysisProfileRun.partially_completed
$log.debug("perform_notifications: NEW Implementation")
    pool = Concurrent::FixedThreadPool.new(PERFORM_NOTIF_THREAD_COUNT)
$log.debug("performing notifs for #{pruns.count} pruns")
    pruns.each do |r|
      pool.post do
$log.debug("[performing notifs for #{r.inspect}]")
$log.debug("[pool: #{pool.inspect}]")
        r.perform_notification(self)
      end
    end
    pool.shutdown
#!!!![should we block? - probably not]:    pool.wait_for_termination
  end

  private

  CREATE_NOTIF_THREAD_COUNT = 4
  PERFORM_NOTIF_THREAD_COUNT = 4

  def initialize
    @notifier_for_mediumtype = {}
    reporter = AnalysisReporter.new
    @notifier_for_mediumtype[medium_types[:email]] = SMTP_Notifier.new(reporter)
    @notifier_for_mediumtype[medium_types[:text]] = TextNotifier.new(reporter)
    @notifier_for_mediumtype[medium_types[:telephone]] = TelephoneNotifier.new(
      reporter)
  end

################################
##########
  # Retrieve each AnalysisProfileRun, apr, whose notifications need
  # initializing and create and initialize its required Notification
  # objects.
  def create_notifications_new
    pruns = AnalysisProfileRun.not_initialized
$log.debug("create_notifications: NEW Implementation")
    pool = Concurrent::FixedThreadPool.new(CREATE_NOTIF_THREAD_COUNT)
$log.debug("creating notifs for #{pruns.count} pruns")
    pruns.each do |r|
      pool.post do
$log.debug("[processing #{r.inspect}]")
$log.debug("[pool: #{pool.inspect}]")
        create_notifications_for(r)
      end
    end
    pool.shutdown
    pool.wait_for_termination
    # (Assert that all pruns are initialized.)
    if pruns.any? {|r| r.not_initialized? || r.initializing? } then
      raise "code defect: target AnalysisProfileRuns were not initialized"
    end
  end
##########

  # Retrieve each AnalysisProfileRun, apr, whose notifications need
  # to be sent and attempt to send them.
  def perform_notifications__new
    pruns = AnalysisProfileRun.initialized +
      AnalysisProfileRun.partially_completed
$log.debug("perform_notifications: NEW Implementation")
    pool = Concurrent::FixedThreadPool.new(PERFORM_NOTIF_THREAD_COUNT)
$log.debug("performing notifs for #{pruns.count} pruns")
    pruns.each do |r|
      pool.post do
$log.debug("[executing notifs for #{r.inspect}]")
$log.debug("[pool: #{pool.inspect}]")
        execute_notifications_for(r)
      end
    end
    pool.shutdown
    pool.wait_for_termination
  end

end

class NEW_AnalysisResultsProcessor
  include Contracts::DSL

  public  ###  Access

  # Known types of notification media
  # Hash table: type-name => enum-value
  def medium_types
    if @medium_types.nil? then
      @medium_types = NotificationAddress.medium_types
    end
    @medium_types
  end

  # A new notifier for 'o' of the right type, based on "o"'s medium_type
  pre  :o_exists do |o| ! o.nil? end
  post :result_exists do |result| ! result.nil? end
  def notifier_for(o)
    key = medium_types[o.medium_type]
    result = @notifier_for_mediumtype[key]
    result
  end

  public  ###  Basic operations

  # Retrieve each AnalysisProfileRun, apr, whose notifications need
  # initializing and create and initialize its required Notification
  # objects.
  def create_notifications
    pruns = AnalysisProfileRun.not_initialized
$log.debug("create_notifications: NEW Implementation")
    pool = Concurrent::FixedThreadPool.new(CREATE_NOTIF_THREAD_COUNT)
$log.debug("creating notifs for #{pruns.count} pruns")
    pruns.each do |r|
      pool.post do
$log.debug("[processing #{r.inspect}]")
$log.debug("[pool: #{pool.inspect}]")
        create_notifications_for(r)
      end
    end
    pool.shutdown
    pool.wait_for_termination
    # (Assert that all pruns are initialized.)
    if pruns.any? {|r| r.not_initialized? || r.initializing? } then
      raise "code defect: target AnalysisProfileRuns were not initialized"
    end
  end

  # Retrieve each AnalysisProfileRun, apr, whose notifications need
  # to be sent and attempt to send them.
  def perform_notifications
    pruns = AnalysisProfileRun.initialized +
      AnalysisProfileRun.partially_completed
$log.debug("perform_notifications: NEW Implementation")
    pool = Concurrent::FixedThreadPool.new(PERFORM_NOTIF_THREAD_COUNT)
$log.debug("performing notifs for #{pruns.count} pruns")
    pruns.each do |r|
      pool.post do
$log.debug("[executing notifs for #{r.inspect}]")
$log.debug("[pool: #{pool.inspect}]")
        execute_notifications_for(r)
      end
    end
    pool.shutdown
    pool.wait_for_termination
  end

  private

  def initialize
    @notifier_for_mediumtype = {}
    reporter = AnalysisReporter.new
    @notifier_for_mediumtype[medium_types[:email]] = SMTP_Notifier.new(reporter)
    @notifier_for_mediumtype[medium_types[:text]] = TextNotifier.new(reporter)
    @notifier_for_mediumtype[medium_types[:telephone]] = TelephoneNotifier.new(
      reporter)
  end

  private  ###  Implementation

  CREATE_NOTIF_THREAD_COUNT = 4
  PERFORM_NOTIF_THREAD_COUNT = 4

  # Create/initialize all needed Notifications for AnalysisProfileRun r.
  # (If r is found to be locked, abandon the operation.)
  pre :init_pending do |r| r.not_initialized? end
  def create_notifications_for(r)
    r.transaction do
      r.initializing!
      r.save!
      r.create_notifications
      r.initialized!
      r.save!
      $log.debug("(create_notifications_for finished [r: #{r.inspect}])")
    end
  rescue ActiveRecord::StaleObjectError => e
    $log.debug("optimistic lock failed in 'create_notifications_for' for " +
               "#{r.inspect} -\nskipping (#{e})")
  rescue ActiveRecord::StatementInvalid => e
    $log.debug("optimistic lock failed in 'create_notifications_for' with " +
               "ActiveRecord::StatementInvalid for " +
               "#{r.inspect} -\nskipping (#{e})")
  rescue ActiveRecord::ActiveRecordError => exception
puts "[ARP.cnf] transaction failed: #{exception}!!!!"
    #!!!!!TO-DO: error handling!!!!
    raise exception
  end

  # Execute the Notifications for AnalysisProfileRun r.
  # (If r is found to be locked, abandon the operation.)
  pre :notif_pending do |r| r.initialized? || r.partially_completed? end
  def execute_notifications_for(r)
    r.transaction do
      # If we have the lock, indicate processing of r's notifications:
      r.in_progress!
      r.save!
      r.perform_notification(self)
      r.save!
      $log.debug("(execute_notifications_for finished) [r: #{r.inspect}]")
    end
  rescue ActiveRecord::StaleObjectError => e
    $log.debug("optimistic lock failed in 'execute_notifications_for' for " +
               "#{r.inspect} -\nskipping (#{e})")
  rescue ActiveRecord::StatementInvalid => e
    $log.debug("optimistic lock failed in 'execute_notifications_for' with " +
               "ActiveRecord::StatementInvalid for " +
               "#{r.inspect} -\nskipping (#{e})")
  rescue ActiveRecord::ActiveRecordError => exception
puts "[ARP.enf] transaction failed: #{exception}!!!!!"
    #!!!!!TO-DO: error handling!!!!
    raise exception
  end

end
