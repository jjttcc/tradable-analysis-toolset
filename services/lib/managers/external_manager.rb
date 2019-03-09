require 'service_manager'

# ServiceManagers responsible for managing an external, non-rails-dependent
# process.
class ExternalManager < ServiceManager
  include Contracts::DSL

  public

  def block_until_started
puts "I'm running the task..."
STDOUT.flush
    run_program
puts "I ran the task."
STDOUT.flush
  end

  private

  # Mapping of service symbol-tags to executable file paths
  PATH_FOR = {
#    CREATE_NOTIFICATIONS     => 'analysis:create_notifications',
#    FINISH_NOTIFICATIONS     => 'analysis:finish_notifications',
#    PERFORM_NOTIFICATIONS    => 'analysis:perform_notifications',
#    PERFORM_ANALYSIS         => 'analysis:perform_analysis',
#    START_ANALYSIS_SERVICE   => 'analysis_startup:start_analysis_service',
#    START_POST_PROCESSING_SERVICE =>
#      'analysis_startup:start_post_processing_service',
    EOD_DATA_RETRIEVAL       => 'services/non_rails//eod_data_retrieval.rb'
  }

  def run_program
    path = PATH_FOR[tag]
#!!!!TO-DO: harden/error-handling/...
puts "[rp] 1"
STDOUT.flush
    child = fork do
puts "[rp] 2"
      exec(path)
puts "[rp] 3"
    end
puts "[rp] 4"
    Process.detach(child)
#!!!maybe this one instead: Process.daemon(child)
puts "[rp] 5"
  end

  private  ###  Initialization

  def initialize(tag:)
    super(tag: tag)
  end

end
