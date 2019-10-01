
# Services-management configuration
class ServiceConfiguration
  include Contracts::DSL

  public  ###  Access

  post :is_class do |result| result.is_a?(Class) end
  post :is_srvc_conf do |result| result == TradableTrackingManager end
  def self.tradable_tracker
    TradableTrackingManager
  end

  post :is_class do |result| result.is_a?(Class) end
  post :is_srvc_conf do |result| result == ExchangeScheduleMonitor end
  def self.exchange_schedule_monitor
    ExchangeScheduleMonitor
  end

  post :is_class do |result| result.is_a?(Class) end
  post :is_srvc_conf do |result| result == EODEventManager end
  def self.eod_event_manager
    EODEventManager
  end

  post :is_class do |result| result.is_a?(Class) end
  post :is_srvc_conf do |result| result == EODRetrievalManager end
  def self.eod_retrieval_manager
    EODRetrievalManager
  end

  post :is_class do |result| result.is_a?(Class) end
  post :is_srvc_conf do |result| result == StatusReporting end
  def self.status_reporting_manager
    StatusReporting
  end

  post :is_class do |result| result.is_a?(Class) end
  post :is_srvc_conf do |result| result == ReportManager end
  def self.reporting_administrator
    ReportManager
  end

end
