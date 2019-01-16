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

  ###  Basic operations

  # Open a transaction and:  if optimistic locking does not cause abortion
  # of the operation (i.e., another thread or process has it locked) and if
  # 'has_events?' and notification_status is 'not_initialized':
  #   - Create and initialize a Notification object for each of
  #     'analysis_profile.notification_addresses'.
  #   - Ensure each of the affected notifications has a status of 'initial'.
  #   - Ensure that notification_status is 'initialized'.
  #   - Save the resulting new state before ending the transaction.
  # If the transaction fails (most likely due to 'self' already being
  # locked), an appropriate exception is raised.
  pre  :profile_exists  do has_profile? end
  def create_notifications
    if has_events? then
      transaction do
        reload
        if not_initialized? then
          notification_status_will_change!
          initializing!
          save!
          create_new_notifications
        else
          # The job has already been done (e.g., by another thread or process).
        end
      end
    end
  rescue ActiveRecord::StaleObjectError, ActiveRecord::StatementInvalid => e
    $log.warn("[#{__method__}] transaction failed - likely due to DB lock " +
              "(#{e})")
    raise e
  rescue StandardError => e
    $log.warn("[#{__method__}] transaction failed: #{e}")
    raise e
  end

  # Open a transaction and:  if optimistic locking does not cause abortion
  # of the operation (i.e., another thread or process has it locked) and if
  # notification_status is 'initialized' or 'partially_completed':
  #   - Using 'initiator' to obtain the correct "notifier" (based on
  #     medium_type), use the resulting notifier to perform all configured
  #     notifications regarding all events (AnalysisEvent) contained by
  #     'analysis_runs'.
  #   - Ensure each of the affected notifications has a status of 'sent',
  #     'delivered', 'failed', or 'again'.
  #   - Ensure that notification_status is 'initialized',
  #     'partially_completed', or 'fully_completed.
  #   - Save the resulting new state before ending the transaction.
  # If the transaction fails (most likely due to 'self' already being
  # locked), an appropriate exception is raised.
  pre  :profile_exists  do has_profile? end
  def perform_notification(initiator)
    transaction do
      reload
      if initialized? || partially_completed? then
        notification_status_will_change!
        in_progress!
        save!
        execute_pending_notifications(initiator)
      else
        # The job has already been done (e.g., by another thread or process).
      end
    end
  rescue ActiveRecord::StaleObjectError, ActiveRecord::StatementInvalid => e
    $log.warn("[#{__method__}] transaction failed - likely due to DB lock " +
              "(#{e})")
    raise e
  rescue StandardError => e
    $log.warn("[#{__method__}] transaction failed: #{e}")
    raise
  end

  private  ###  Implementation

  pre  :initializing do initializing? end
  post :initialized do initialized? end
  post :notifications_prepared do
    analysis_profile.notification_addresses.all? { |a|
      notifications.any? {|n| n.contact_identifier == a.contact_identifier &&
        n.initial? && n.notification_source == self } } end
  def create_new_notifications
    analysis_profile.notification_addresses.each do |addr|
      n = Notification.new(notification_source: self,
                           contact_identifier: addr.contact_identifier,
                           medium_type: addr.medium_type,
                           user: analysis_profile.user)
      n.initial!  # I.e., set 'status' to "initial".
    end
    initialized!
    save!
  end

  pre  :reserved_by_me do in_progress? end
  post :finished_state do
    initialized? || partially_completed? || fully_completed? end
  def execute_pending_notifications(initiator)
    notifiers = {}
    completed_count = 0
    selected_notifs = notifications.select do |n|
      n.initial? || n.again?
    end
    old_selected_statuses = selected_notifs.map do |n|
      n.status
    end
    selected_notifs.each do |n|
      notifier = initiator.notifier_for(n)
      if notifier.nil? then
        $log.debug("notifier for notification #{n} not found.")
        raise "!!!!TO-DO: fix code bug or missing error logic!!!!!"
      end
      notifier.notifications << n
      if ! notifiers[notifier] then
        notifiers[notifier] = true
      end
    end
    notifiers.keys.each do |notifier|
      notifier.execute(self)
      notifier.notifications.each do |n|
        # Save 'sent', 'delivered', 'failed', or 'again' state.
        n.save
      end
      notifier.clear_notifications
    end
    set_new_notification_status(selected_notifs, old_selected_statuses)
    save!
  end

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
          selected_notifs[i].status != original_statuses[i]
        then
          cur_notif = selected_notifs[i]
          if cur_notif.sent? || cur_notif.delivered? || cur_notif.failed? then
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
