# Constants and other "facilities" used by/for the TAT services
#!!!!!NOTE: This file might belong somewhere else - not in .../redis!!!!!
#!!!change to: module TatServicesFacilities
module TatServicesFacilities
  public  ### redis-related constants

  EOD_CHECK_CHANNEL             = 'eod-checktime'
  EOD_DATA_CHANNEL              = 'eod-data-ready'
  EOD_CHECK_KEY_BASE            = 'eod-check-symbols'
  EOD_DATA_KEY_BASE             = 'eod-ready-symbols'
  ANALYSIS_REQUEST_CHANNEL      = 'analysis-requests'
  NOTIFICATION_CREATION_CHANNEL = 'notification-creation-requests'
  NOTIFICATION_DISPATCH_CHANNEL = 'notification-dispatch-requests'

  public  ### redis-related constant-based key values

  # new key for symbol set associated with "check for eod data" notifications
  def new_eod_check_key
    EOD_CHECK_KEY_BASE + rand(1..9999999999).to_s
  end

  # new key for symbol set associated with eod-data-ready notifications
  def new_eod_data_ready_key
    EOD_DATA_KEY_BASE + rand(1..9999999999).to_s
  end

end

orig_verbose = $VERBOSE
# Suppress the constant re-initialization warnings for the block below:
$VERBOSE = nil

if ENV.has_key?('RAILS_ENV') && ENV['RAILS_ENV'] == 'test' then
  # This is a test.  This is only a test...
  # https://www.youtube.com/watch?v=eic8hJu0sQ8
  TatServicesFacilities::EOD_CHECK_CHANNEL          = 'eod-checktime-test'
  TatServicesFacilities::EOD_DATA_CHANNEL           = 'eod-data-ready-test'
  TatServicesFacilities::EOD_CHECK_KEY_BASE         = 'eod-check-symbols-test'
  TatServicesFacilities::EOD_DATA_KEY_BASE          = 'eod-ready-symbols-test'
  TatServicesFacilities::ANALYSIS_REQUEST_CHANNEL   = 'analysis-requests-test'
  TatServicesFacilities::NOTIFICATION_CREATION_CHANNEL =
    'notification-creation-requests-test'
  TatServicesFacilities::NOTIFICATION_DISPATCH_CHANNEL =
    'notification-dispatch-requests-test'
end

# And, of course, restore the re-initialization warnings:
$VERBOSE = orig_verbose
