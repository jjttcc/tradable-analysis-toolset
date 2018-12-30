class AnalysisProfileRun < ApplicationRecord
  include Contracts::DSL

  public

  belongs_to :user
  belongs_to :analysis_profile
  has_many   :analysis_runs
  has_many   :notifications, as: :notification_source, dependent: :destroy

  public

  ###  Access

  post :exists do |result| ! result.nil? end
  def all_events
    if @all_events.nil? then
      @all_events = []
      analysis_runs.each do |r|
        @all_events.concat(r.all_events)
      end
    end
    @all_events
  end

  ###  Status report

  # Does 'self' have at least one event?
  post :foo do |result| result == all_events.count > 0 end
  def has_events?
    all_events.count > 0
  end

  def notification_pending?
    has_events? && (notifications.empty? || notifications[0].initial?)
  end

  ###  Basic operations

  # Create and initialize a Notification object for each of
  # 'analysis_profile.notification_addresses.
  pre :profile_exists do analysis_profile != nil end
  def prepare_for_notification
    analysis_profile.notification_addresses.each do |addr|
      n = Notification.new(notification_source: self,
                           contact_identifier: addr.contact_identifier,
                           medium_type: addr.medium_type,
                           user: analysis_profile.user)
      n.initial!  # I.e., set 'status' to "initial".
    end
  end

  # Using 'initiator' to obtain the correct "notifier" (based on
  # medium_type), use the resulting notifier to perform all configured
  # notifications regarding all events (AnalysisEvent) contained by
  # 'analysis_runs'.
  def perform_notification(initiator)
    notifiers = {}
    notifications.each do |n|
      notifier = initiator.notifier_for(n)
      if notifier.nil? then
        raise "naughty, naughty [FIX THIS ERROR MSG/HANDLING, PLeASE!!!"#!!!
      end
      notifier.notifications << n
      if ! notifiers[notifier] then
        notifiers[notifier] = true
      end
    end
    notifiers.keys.each do |notifier|
      notifier.execute(self)
      notifier.clear_notifications
    end
  end

  # Using 'initiator' to obtain the correct "notifier" (based on
  # medium_type), use the resulting notifier to perform all configured
  # notifications regarding all events (AnalysisEvent) contained by
  # 'analysis_runs'.
#!!!!
  def old_throw_away___perform_notification(initiator)
    notifiers = []
    notifications.each do |n|
      notifier = initiator.notifier_for(n)
      if notifier.nil? then
        raise "naughty, naughty [FIX THIS ERROR MSG/HANDLING, PLeASE!!!"#!!!
      end
      notifier.notifications << n
      notifiers << notifier
    end
    notifiers.each do |notifier|
      notifier.execute(self)
      notifier.clear_notifications
    end
  end

end
