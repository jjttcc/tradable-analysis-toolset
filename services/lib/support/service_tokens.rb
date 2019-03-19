# Symbols, constants, method names, etc. used for TAT services
module ServiceTokens

  public

  # Symbol-tags for services
  REDIS                         = :redis
  CREATE_NOTIFICATIONS          = :create_notifications
  FINISH_NOTIFICATIONS          = :finish_notifications
  PERFORM_NOTIFICATIONS         = :perform_notifications
  PERFORM_ANALYSIS              = :perform_analysis
  START_ANALYSIS_SERVICE        = :start_analysis_service
  START_POST_PROCESSING_SERVICE = :start_post_processing_service
  EOD_DATA_RETRIEVAL            = :eod_data_retrieval
  EOD_EXCHANGE_MONITORING       = :eod_exchange_monitoring
  MANAGE_TRADABLE_TRACKING      = :manage_tradable_tracking

  SERVICE_EXISTS = Hash[
    [REDIS, CREATE_NOTIFICATIONS, FINISH_NOTIFICATIONS, PERFORM_NOTIFICATIONS,
    PERFORM_ANALYSIS, START_ANALYSIS_SERVICE, START_POST_PROCESSING_SERVICE,
    EOD_DATA_RETRIEVAL, EOD_EXCHANGE_MONITORING,
    MANAGE_TRADABLE_TRACKING].map do |s|
      [s, true]
    end
  ]

  # Mapping of the rake-task symbol-tags to status keys
  STATUS_KEY_FOR = {
    CREATE_NOTIFICATIONS          => "#{CREATE_NOTIFICATIONS}_status",
    FINISH_NOTIFICATIONS          => "#{FINISH_NOTIFICATIONS}_status",
    PERFORM_NOTIFICATIONS         => "#{PERFORM_NOTIFICATIONS}_status",
    PERFORM_ANALYSIS              => "#{PERFORM_ANALYSIS}_status",
    START_ANALYSIS_SERVICE        => "#{START_ANALYSIS_SERVICE}_status",
    START_POST_PROCESSING_SERVICE => "#{START_POST_PROCESSING_SERVICE}_status",
    EOD_DATA_RETRIEVAL            => "#{EOD_DATA_RETRIEVAL}_status",
    EOD_EXCHANGE_MONITORING       => "#{EOD_EXCHANGE_MONITORING}_status",
    MANAGE_TRADABLE_TRACKING      => "#{MANAGE_TRADABLE_TRACKING}_status",
  }

  # Mapping of the rake-task symbol-tags to status keys
  CONTROL_KEY_FOR = {
    CREATE_NOTIFICATIONS          => "#{CREATE_NOTIFICATIONS}_control",
    FINISH_NOTIFICATIONS          => "#{FINISH_NOTIFICATIONS}_control",
    PERFORM_NOTIFICATIONS         => "#{PERFORM_NOTIFICATIONS}_control",
    PERFORM_ANALYSIS              => "#{PERFORM_ANALYSIS}_control",
    START_ANALYSIS_SERVICE        => "#{START_ANALYSIS_SERVICE}_control",
    START_POST_PROCESSING_SERVICE => "#{START_POST_PROCESSING_SERVICE}_control",
    EOD_DATA_RETRIEVAL            => "#{EOD_DATA_RETRIEVAL}_control",
    EOD_EXCHANGE_MONITORING       => "#{EOD_EXCHANGE_MONITORING}_control",
    MANAGE_TRADABLE_TRACKING      => "#{MANAGE_TRADABLE_TRACKING}_control",
  }

=begin
  # Key values used for messaging
  EXCHANGE_MONITOR_CONTROL_KEY  = 'exchange-monitor-control'
  TRADABLE_TRACKING_CONTROL_KEY = 'tradable-tracking-control'
  EOD_RETRIEVAL_CONTROL_KEY     = 'eod-data-retrieval-control'

  # Mapping of the rake-task symbol-tags to control keys
  CONTROL_KEY_FOR = {
    CREATE_NOTIFICATIONS     => nil,  # ut supra
    FINISH_NOTIFICATIONS     => nil,
    PERFORM_NOTIFICATIONS    => nil,
    PERFORM_ANALYSIS         => nil,
    START_ANALYSIS_SERVICE   => nil,
    START_POST_PROCESSING_SERVICE => nil,
    EOD_DATA_RETRIEVAL       => EOD_RETRIEVAL_CONTROL_KEY,
    EOD_EXCHANGE_MONITORING  => EXCHANGE_MONITOR_CONTROL_KEY,
    MANAGE_TRADABLE_TRACKING => TRADABLE_TRACKING_CONTROL_KEY,
  }
=end

end
