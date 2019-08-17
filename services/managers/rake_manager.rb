require 'service_manager'

# ServiceManagers responsible for managing a rake task/process.
class RakeManager < ServiceManager
  include Contracts::DSL

  private

  @@rake_command = 'rake'

  # Mapping of service symbol-tags to task names
  TASK_NAME_FOR = {
    CREATE_NOTIFICATIONS     => 'analysis:create_notifications',
    FINISH_NOTIFICATIONS     => 'analysis:finish_notifications',
    PERFORM_NOTIFICATIONS    => 'analysis:perform_notifications',
    PERFORM_ANALYSIS         => 'analysis:perform_analysis',
    START_ANALYSIS_SERVICE   => 'analysis_startup:start_analysis_service',
    START_POST_PROCESSING_SERVICE =>
      'analysis_startup:start_post_processing_service',
    EOD_EXCHANGE_MONITORING  => 'eod_exchange_monitoring',
    MANAGE_TRADABLE_TRACKING => 'manage_tradable_tracking',
    EOD_EVENT_TRIGGERING     => 'manage_event_triggering',
    TRIGGER_PROCESSING       => 'manage_trigger_processing',
    NOTIFICATION_PROCESSING  => 'manage_notifications',
  }

  private  ### Hook method implementations

  # Fork a child process and run the task associated with 'tag' in the
  # child process.
  def start_service
    task = TASK_NAME_FOR[tag]
#!!!!TO-DO: harden/error-handling/...
    child = fork do
      exec(@@rake_command, task)
    end
    Process.detach(child)
#!!!maybe this one instead: Process.daemon(child)
  end

end
