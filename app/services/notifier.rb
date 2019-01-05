# Objects that use the information in a specified 'Notification' to perform
# the resulting configured notification.!!!!!MORE NEEDED!!!!!
# !!!rm:Note: The 'dup' method initializes the attributes 'notification' and
# !!!rm:'execution_succeeded' to nil.  This behavior will be maintained in
# !!!rm:descendant classes, unless 'initialize_copy' has been redefined.
class Notifier
  include Contracts::DSL

  public

  attr_accessor :notifications, :execution_succeeded, :report_extractor

  # Perform the required notifications - i.e., message delivery, using
  # 'notifications' to direct the message and 'notification_source' to build
  # the message to be sent.
  pre  :notification_set do notifications != nil end
  pre  :reporter_set do report_extractor != nil end
  post :exec_status do execution_succeeded != nil end
  post :send_attempted do notifications.each { |n| n.sent? || n.delivered? ||
                                               n.failed? || n.again? } end
  def execute(notification_source)
    prepare_for_execution(notification_source)
    perform_execution(notification_source)
#!!!!!TO-DO: when a temporary failure is detected, set!!!!!
#!!!!!'notification.again!' instead of 'notification.failed!'!!!
    postprocess_execution(notification_source)
  end

  # Empty the 'notifications' array.
  post :no_notfications do notifications.empty? end
  def clear_notifications
    @notifications = []
  end

  private

  ###  Initialization

  pre  :reporter_exists do |reporter| ! reporter.nil? end
  post :notifications_empty do notifications == [] end
  post :reporter_set do |result, reporter| report_extractor == reporter end
  def initialize(reporter = nil)
    self.report_extractor = reporter
    @notifications = []
  end

  ###  Copying - implementation

  post :notifications_empty do notifications == [] end
#!!!!!NOTE: This method is probably not needed and, if so, should be removed!!!
  def initialize_copy(original)
    super(original)
    @notifications = []
    @execution_succeeded = nil
  end

  ### Hook routines

  post :exec_status do execution_succeeded != nil end
  def perform_execution(notification_source)
    raise "abstract method: Notifier.perform_execution"
  end

  ### Hook routine default implementations

  def prepare_for_execution(notification_source)
    notifications.each do |n| n.sending! end
  end

  def postprocess_execution(notification_source)
    # default: do nothing
  end

end
