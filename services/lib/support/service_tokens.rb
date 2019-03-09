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

  # Key values used for messaging
  EXCHANGE_MONITOR_STATUS_KEY   = 'exchange-monitor-run-state'
  TRADABLE_TRACKING_STATUS_KEY  = 'tradable-tracking-run-state'
  EOD_RETRIEVAL_STATUS_KEY      = 'eod-data-retrieval-run-state'
  EXCHANGE_MONITOR_CONTROL_KEY  = 'exchange-monitor-control'
  TRADABLE_TRACKING_CONTROL_KEY = 'tradable-tracking-control'
  EOD_RETRIEVAL_CONTROL_KEY     = 'eod-data-retrieval-control'

  # Mapping of the rake-task symbol-tags to status keys
  STATUS_KEY_FOR = {
    CREATE_NOTIFICATIONS     => nil,  # unused or "to-be-defined"
    FINISH_NOTIFICATIONS     => nil,  # ut supra
    PERFORM_NOTIFICATIONS    => nil,  # ...
    PERFORM_ANALYSIS         => nil,
    START_ANALYSIS_SERVICE   => nil,
    START_POST_PROCESSING_SERVICE => nil,
    EOD_DATA_RETRIEVAL       => EOD_RETRIEVAL_STATUS_KEY,
    EOD_EXCHANGE_MONITORING  => EXCHANGE_MONITOR_STATUS_KEY,
    MANAGE_TRADABLE_TRACKING => TRADABLE_TRACKING_STATUS_KEY,
  }

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

end
