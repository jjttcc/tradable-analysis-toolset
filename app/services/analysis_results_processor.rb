# !!!!TO-DO: Delete all AnalysisRuns (after processing/notification) whose
# parent AnalysisProfileRun has 'expiration_date' <= now.
# !!!!To-do2: Add header comments/description here.
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
    orig = @notifier_for_mediumtype[key]
#!!!!    result = orig.dup
    result = orig
    result
  end

  public  ###  Basic operations

  def execute(user: nil)
    if user.nil? then
      pruns = AnalysisProfileRun.all
    else
      pruns = user.analysis_profile_runs
    end
    target_pruns = pruns.select do |r|
      r.notification_pending?
    end
    prepare_for_notification(target_pruns)
    execute_notifications(target_pruns)
    save_notification_results(target_pruns)
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

  def prepare_for_notification(pruns)
    User.transaction do
      pruns.each do |r|
        r.prepare_for_notification
        r.save!
      end
    end
  rescue ActiveRecord::ActiveRecordError => exception
puts "[ARP.pfn] transaction failed: #{exception}"
raise exception
    #!!!!!TO-DO: error handling!!!!
  end

  def execute_notifications(pruns)
      pruns.each do |r|
        r.perform_notification(self)
      end
  end

  def save_notification_results(pruns)
    #!!!!!TO-DO: save successful or failed runs' new state to DB!!!!!!
  end


end
