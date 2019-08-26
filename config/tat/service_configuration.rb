
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

end
