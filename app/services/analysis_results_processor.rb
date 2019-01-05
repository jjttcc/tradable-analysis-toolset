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

  # Retrieve each AnalysisProfileRun, apr, whose notifications need
  # initializing and create and initialize its required Notification
  # objects.
  def create_notifications
    pruns = AnalysisProfileRun.not_initialized
    pruns.each do |r|
      create_notifications_for(r)
    end
  end

  # Retrieve each AnalysisProfileRun, apr, whose notifications need
  # to be sent and attempt to send them.
  def perform_notifications
    pruns = AnalysisProfileRun.initialized +
      AnalysisProfileRun.partially_completed
    pruns.each do |r|
      execute_notifications_for(r)
    end
  end

  private

  #!!!!(remove)
  def obsolete___execute(user: nil)
    if user.nil? then
      pruns = AnalysisProfileRun.all
    else
      pruns = user.analysis_profile_runs
    end
    target_pruns = pruns.select do |r|
      r.notification_needed?
    end
    create_notifications_for(target_pruns)
    execute_notifications_for(target_pruns)
    save_notification_results(target_pruns)
  end

  def initialize
    @notifier_for_mediumtype = {}
    reporter = AnalysisReporter.new
    @notifier_for_mediumtype[medium_types[:email]] = SMTP_Notifier.new(reporter)
    @notifier_for_mediumtype[medium_types[:text]] = TextNotifier.new(reporter)
    @notifier_for_mediumtype[medium_types[:telephone]] = TelephoneNotifier.new(
      reporter)
  end

  private  ###  Implementation

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
puts "[ARP.pfn] transaction failed: #{exception}"
raise exception
    #!!!!!TO-DO: error handling!!!!
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
puts "[ARP.pfn] transaction failed: #{exception}"
raise exception
    #!!!!!TO-DO: error handling!!!!
  end

  def obsolete___save_notification_results(pruns)
#!!!!QUESTION: Should the pruns be saved here or within!!!!
#!!!!'execute_notifications'?!!!!!
    User.transaction do
      pruns.each do |r|
        r.save!
      end
    end
  rescue ActiveRecord::ActiveRecordError => exception
    raise exception
  end

end
