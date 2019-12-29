require 'service_manager'

# ServiceManagers responsible for managing an external, non-rails-dependent
# process.
class ExternalManager < ServiceManager
  include Contracts::DSL

  private

  # (i.e., redefine log method as an attribute.)
  attr_reader :log, :path

  # Mapping of service symbol-tags to executable file paths
  PATH_FOR = {
#    CREATE_NOTIFICATIONS     => 'analysis:create_notifications',
#    FINISH_NOTIFICATIONS     => 'analysis:finish_notifications',
#    PERFORM_NOTIFICATIONS    => 'analysis:perform_notifications',
#    PERFORM_ANALYSIS         => 'analysis:perform_analysis',
#    START_ANALYSIS_SERVICE   => 'analysis_startup:start_analysis_service',
#    START_POST_PROCESSING_SERVICE =>
#      'analysis_startup:start_post_processing_service',
    EOD_DATA_RETRIEVAL => 'top_level/eod_data_retrieval.rb',
    STATUS_REPORTING   => 'top_level/status_reporter.rb'
  }

  def start_service
#!!!!TO-DO: harden/error-handling/...
    child = fork do
      exec(path)
    end
    Process.detach(child)
#!!!maybe this one instead: Process.daemon(child)
  end

  private  ###  Initialization

  pre :config_exists do |config| config != nil end
  def initialize(config, tag, path_override = nil)
    @log = config.error_log
    if path_override.nil? then
      @path = PATH_FOR[tag]
    else
      @path = path_override
    end
    super(config, tag)
  end

end
