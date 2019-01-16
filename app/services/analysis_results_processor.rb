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

  # Retrieve each AnalysisProfileRun whose notifications need initializing
  # and attempt to create and initialize its required Notification objects.
  def create_notifications
    pruns = AnalysisProfileRun.not_initialized
    pruns.each do |r|
      r.create_notifications
    end
  end

  # Retrieve each AnalysisProfileRun whose notifications need
  # to be sent and attempt to send them.
  def perform_notifications
    pruns = AnalysisProfileRun.initialized +
      AnalysisProfileRun.partially_completed
    pruns.each do |r|
      r.perform_notification(self)
    end
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

end
