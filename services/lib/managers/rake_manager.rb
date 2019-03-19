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
    EOD_EXCHANGE_MONITORING  => 'eod_exchange_monitoring_startup',
    MANAGE_TRADABLE_TRACKING => 'manage_tradable_tracking',
  }

  private  ### Hook method implementations

  # Fork a child process and run the task associated with 'tag' in the
  # child process.
  def start_service
    task = TASK_NAME_FOR[tag]
#!!!!TO-DO: harden/error-handling/...
puts "1"
STDOUT.flush
    child = fork do
puts "a"
STDOUT.flush
      exec(@@rake_command, task)
puts "b"
STDOUT.flush
    end
puts "A"
STDOUT.flush
    Process.detach(child)
#!!!maybe this one instead: Process.daemon(child)
puts "B"
STDOUT.flush
  end

end
