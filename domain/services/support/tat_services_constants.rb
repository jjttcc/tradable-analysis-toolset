# Constants relevant to TAT services
module TatServicesConstants
  public

  if
    (ENV.has_key?('RAILS_ENV') && ENV['RAILS_ENV'] == 'test') ||
    (ENV.has_key?('TAT_ENV') && ENV['TAT_ENV'] == 'test')
  then
puts "Using test constants" #!!!!
    EOD_CHECK_KEY_BASE            = 'eod-check-symbols-test'
    EOD_DATA_KEY_BASE             = 'eod-ready-symbols-test'
    EXCHANGE_CLOSE_TIME_KEY       = 'exchange-next-close-time-test'
    OPEN_EXCHANGES_KEY            = 'exchange-open-exchanges-test'
    # publish/subscribe channels
    EOD_CHECK_CHANNEL             = 'eod-checktime-test'
    EOD_DATA_CHANNEL              = 'eod-data-ready-test'
    TRIGGERED_EVENTS_CHANNEL      = 'triggering-completed-test'
    TRIGGERED_RESPONSE_CHANNEL    = 'trigger-response-test'
    NOTIFICATION_CREATION_CHANNEL = 'notification-creation-requests-test'
    NOTIFICATION_DISPATCH_CHANNEL = 'notification-dispatch-requests-test'
#!!!    STATUS_REPORTING_CHANNEL      = 'status-reporting-test'
#!!!!!Check - no "-test"':
    STATUS_REPORTING_CHANNEL      = 'status-reporting'
#!!!    REPORT_RESPONSE_CHANNEL       = 'status-reporting-response-test'
#!!!!!Check - no "-test"':
    REPORT_RESPONSE_CHANNEL       = 'status-reporting-response'

    EOD_CHECK_QUEUE = 'eod-check-queue-test'
    EOD_READY_QUEUE = 'eod-data-ready-queue-test'
  else
    EOD_CHECK_KEY_BASE            = 'eod-check-symbols'
    EOD_DATA_KEY_BASE             = 'eod-ready-symbols'
    EXCHANGE_CLOSE_TIME_KEY       = 'exchange-next-close-time'
    OPEN_EXCHANGES_KEY            = 'exchange-open-exchanges'
    # publish/subscribe channels
    EOD_CHECK_CHANNEL             = 'eod-checktime'
    EOD_DATA_CHANNEL              = 'eod-data-ready'
    TRIGGERED_EVENTS_CHANNEL      = 'triggering-completed'
    TRIGGERED_RESPONSE_CHANNEL    = 'trigger-response'
    NOTIFICATION_CREATION_CHANNEL = 'notification-creation-requests'
    NOTIFICATION_DISPATCH_CHANNEL = 'notification-dispatch-requests'
    STATUS_REPORTING_CHANNEL      = 'status-reporting'
    REPORT_RESPONSE_CHANNEL       = 'status-reporting-response'

    EOD_CHECK_QUEUE = 'eod-check-queue'
    EOD_READY_QUEUE = 'eod-data-ready-queue'
  end

  CLOSE_DATE_SUFFIX               = 'close-date'

  EXMON_PAUSE_SECONDS, EXMON_LONG_PAUSE_ITERATIONS = 3, 35
  RUN_STATE_EXPIRATION_SECONDS, DEFAULT_EXPIRATION_SECONDS,
    DEFAULT_ADMIN_EXPIRATION_SECONDS, DEFAULT_APP_EXPIRATION_SECONDS =
      15, 28800, 600, 120
  # Number of seconds of "margin" to give the exchange monitor before the
  # next closing time in order to avoid interfering with its operation:
  PRE_CLOSE_TIME_MARGIN = 300
  # Number of seconds of "margin" to give the exchange monitor after the
  # next closing time in order to avoid interfering with its operation:
  POST_CLOSE_TIME_MARGIN = 90
  # Default number of seconds to wait for a message acknowledgement before
  # giving up:
  MSG_ACK_TIMEOUT = 60  #!!!!tune!!!!

end
