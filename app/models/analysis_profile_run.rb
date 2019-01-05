=begin
analysis_profile_name:   varchar NOT NULL
analysis_profile_client: varchar NOT NULL
run_start_time:          datetime NOT NULL
expiration_date:         datetime NOT NULL
notification_status:     integer DEFAULT 1 NOT NULL
lock_version:            integer DEFAULT 0 NOT NULL
=end

class AnalysisProfileRun < ApplicationRecord
  include Contracts::DSL

  public

  belongs_to :user
  belongs_to :analysis_profile
  has_many   :analysis_runs
  has_many   :notifications, as: :notification_source, dependent: :destroy

  enum notification_status: {
    not_initialized:     1, # notifications not yet created/initialized
    initializing:        2, # notifications are being initialized
    initialized:         3, # "send" attempt not yet made for notifications
    in_progress:         4, # in the process of sending notifications
    partially_completed: 5, # "send" attempts made, some retries pending
    fully_completed:     6, # all "send" attempts and retries completed
  }

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

  # Does 'self' have an associated AnalysisProfile?
  def has_profile?
    analysis_profile != nil
  end

  # Does 'self' have at least one event?
  post :foo do |result| result == all_events.count > 0 end
  def has_events?
    all_events.count > 0
  end

#!!!!Note: This is obsolete - please delete:!!!!!
  # Have all notifications needed by 'self' been created/saved?
  def notifications_initialized?
    ! has_events || (
      ! notifications.empty? && notifications.all? { |n| ! n.new_record })
  end

#!!!!Note: This is obsolete - please delete:!!!!!
  # Do 1 or more notifications need to be sent?
  post :initialized do |result| implies(result, notifications_initialized?) end
  post :needed_iff_events do |result| implies(result, has_events?) end
  def notification_needed?
    has_events? && notifications.any? do |n| n.initial? || n.again? end
  end

  ###  Basic operations

  # Create and initialize a Notification object for each of
  # 'analysis_profile.notification_addresses'.
  pre  :profile_exists  do has_profile? end
  pre  :notifications_being_initialized do initializing? end
  post :notifications_prepared do
    analysis_profile.notification_addresses.all? { |a|
      notifications.any? {|n| n.contact_identifier == a.contact_identifier &&
        n.initial? && n.notification_source == self } } end
  post :notifications_initialized do initialized? end
  def create_notifications
    if has_events? then
      analysis_profile.notification_addresses.each do |addr|
        n = Notification.new(notification_source: self,
                             contact_identifier: addr.contact_identifier,
                             medium_type: addr.medium_type,
                             user: analysis_profile.user)
        n.initial!  # I.e., set 'status' to "initial".
      end
    end
    initialized!
  end

  # Using 'initiator' to obtain the correct "notifier" (based on
  # medium_type), use the resulting notifier to perform all configured
  # notifications regarding all events (AnalysisEvent) contained by
  # 'analysis_runs'.
  pre  :profile_exists  do has_profile? end
  pre  :notification_needed do
    initialized? || partially_completed? || in_progress? end
  post :finished_state do
    initialized? || partially_completed? || fully_completed? end
  def perform_notification(initiator)
    notifiers = {}
    completed_count = 0
    selected_notifs = notifications.select do |n|
      n.initial? || n.again?
    end
    old_selected_statuses = selected_notifs.map do |n|
      n.status
    end
    begin
      selected_notifs.each do |n|
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
      set_new_notification_status(selected_notifs, old_selected_statuses)
    rescue StandardError => e
      set_new_notification_status(selected_notifs, old_selected_statuses)
      raise
    end
  end

  private  ###  Implementation

  # The new 'notification_status' after 'perform_notification'
  post :finished_state do
    initialized? || partially_completed? || fully_completed? end
  def set_new_notification_status(selected_notifs, original_statuses)
    if notifications.all? {|n| n.sent? || n.delivered? || n.failed?} then
      fully_completed!
    else
      # New status cannot be 'fully_completed', so it will be either
      # initialized or partially_completed.
      (0..selected_notifs.count-1).each do |i|
        if
          selected_notifs[i].status != old_selected_statuses[i]
        then
          new_status = selected_notifs[i].status
          if [n.sent, n.delivered, n.failed].include?(new_status) then
            # (We made at least a little progress re notifications, so:)
            partially_completed!
            break
          end
        end
      end
      # (If none of 'selected_notifs' changed status, notification_status
      # will not have changed.)
    end
  end

end
