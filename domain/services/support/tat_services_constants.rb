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
end
