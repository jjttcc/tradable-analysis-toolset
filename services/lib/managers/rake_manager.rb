require 'service_manager'

# ServiceManagers responsible for managing a rake task/process.
class RakeManager < ServiceManager
  include Contracts::DSL

  public

  post :started do is_alive?(tag) end
  def block_until_started
puts "I'm checking if the task (#{tag}) is running..."
STDOUT.flush
    if ! is_alive?(tag) then
puts "#{tag} is NOT running - starting it up..."
      run_task
      sleep FIRST_STARTUP_MARGIN
      if ! is_alive?(tag) then
        sleep SECOND_STARTUP_MARGIN
        if ! is_alive?(tag) then
          raise "#{tag} failed to start in time"
        end
      end
    else
puts "#{tag} is running - nothing to do..."
    end
puts "I made sure task is running."
STDOUT.flush
  end

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

  # Fork a child process and run the task associated with 'tag' in the
  # child process.
  def run_task
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

  private  ###  Initialization

  FIRST_STARTUP_MARGIN = 2.2
  SECOND_STARTUP_MARGIN = 12.5

  def initialize(tag:)
    super(tag: tag)
  end

end
