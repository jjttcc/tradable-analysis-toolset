require "test_helper"

module ModelHelper

  GOOD_ARGS1 = {:email_addr => 'user1@example.org', :password => 'eggfoobar',
                :password_confirmation => 'eggfoobar'}
  GOOD_ARGS2 = {:email_addr => 'tester@professional-testers.org',
                :password => 'barfoobing',
                :password_confirmation => 'barfoobing'}
  BAD_EMAIL1 = {:email_addr => 'tester@professional#testers.org'}
  PERSISTENT_USERS = []
  PERSISTENT_TRIGGERS = []

  # A new user, not saved
  def self.new_user(e)
    result = User.new(GOOD_ARGS1.merge(:email_addr => e))
    PERSISTENT_USERS << result
    result
  end

  # A new user, saved
  def self.new_user_saved(e)
    result = User.new(GOOD_ARGS1.merge(:email_addr => e))
    result.save!
    PERSISTENT_USERS << result
    result
  end

  # Delete persistent users.
  def self.cleanup
    AddressAssignment.delete_all
    AnalysisEvent.delete_all
    AnalysisProfileRun.delete_all
    AnalysisProfile.delete_all
    AnalysisRun.delete_all
    AnalysisSchedule.delete_all
    EventBasedTrigger.delete_all
    EventGenerationProfile.delete_all
    NotificationAddress.delete_all
    Notification.delete_all
    PeriodicTrigger.delete_all
    SymbolListAssignment.delete_all
    SymbolList.delete_all
    TradableEventSet.delete_all
    TradableProcessorParameterSetting.delete_all
    TradableProcessorParameter.delete_all
    TradableProcessorRun.delete_all
    TradableProcessorSpecification.delete_all
    User.delete_all
    MasSession.delete_all
  end

  # A new EventBasedTrigger
  def self.new_eb_trigger(activated = false)
    result = EventBasedTrigger.create(activated: activated)
    PERSISTENT_TRIGGERS << result
    result
  end

  # (Stub) A new PeriodicTrigger
  def self.new_periodic_trigger(interval_seconds = 3600, timew_start, timew_end)
    result = PeriodicTrigger.create(interval_seconds: interval_seconds,
                                    time_window_start: timew_start,
                                    time_window_end: timew_end)
    # ???schedule_type???
    PERSISTENT_TRIGGERS << result
    result
  end

  # A new AnalysisProfile for user 'user', saved to the database
  def self.new_profile_for_user(user, name)
    result = AnalysisProfile.new(name: name)
    result.analysis_client = user
    result.save
    result
  end

  def self.new_notification_address_for_user(user, label,
                                             contact = 'fake@fake.org')
    result = NotificationAddress.new(label: label, contact_identifier: contact)
    result.user = user
    result.email!   # Default medium_type to 'email'.
    result.save
    result
  end

  # ('users' is an array - the address users.)
  def self.new_notification_address_used_by(users, app_user, label,
                                        contact = 'fake@fake.org')
    result = NotificationAddress.new(label: label, contact_identifier: contact,
                                    user: app_user)
    result.text!   # Default medium_type to 'text'.
    users.each do |u|
      u.notification_addresses << result
#puts "added #{result} to #{u.name}'s notif-addrs"
#puts "users of #{result}: #{result.address_users.inspect}"
    end
    result.save
    result
  end

  # A new AnalysisProfile for schedule 'schedule', saved to the database
  def self.new_profile_for_schedule(schedule, name)
    result = AnalysisProfile.new(name: name)
    result.analysis_client = schedule
    result.save
    result
  end

  def self.set_symbol_list_for(owner, name, symbols)
puts "set-symlist - symbols: #{symbols}"
    symbol_ids = nil
    if symbols != nil then
      symbol_ids = []
      symbols.each do |s|
        sid = SymbolList.symbol_id_for(s)
puts "set-symlist - id for #{s}: #{sid}"
        if sid != nil then
          symbol_ids << sid
        end
      end
    end
    list = SymbolList.new(name: name, symbols: symbol_ids)
puts "What did I make? - symbol_ids: #{symbol_ids}\nlist: #{list.inspect}"
    owner.symbol_list = list
    owner.save!
puts "owner: #{owner.inspect}"
    owner
  end

  # A new AnalysisSchedule for 'user' (and 'trigger', if not nil)
  def self.new_schedule_for(user, sched_name, trigger, active = false)
    result = AnalysisSchedule.new(name: sched_name, active: active)
    result.user = user
    if trigger != nil then
      result.trigger = trigger
    end
    result.save
    result
  end

  # A new EventGenerationProfile, attached to 'prof' (AnalysisProfile)
  def self.evgen_profile_for(prof, enddt, period_secs)
    result = EventGenerationProfile.new(end_date: enddt,
        analysis_period_length_seconds: period_secs)
    result.analysis_profile = prof
    result.save
    result
  end

  # A new TradableProcessorSpecification, attached to 'prof' (AnalysisProfile)
  def self.tradable_proc_spec_for(evgen_prof, proc_id, ptype)
    result = TradableProcessorSpecification.new(processor_id: proc_id,
                                                 period_type: ptype)
    result.event_generation_profile = evgen_prof
    result.save
    result
  end

  # A new TradableProcessorParameter, attached to 'tp_spec'
  # (TradableProcessorSpecification)
  def self.tradable_proc_parameter_for(tp_spec, name, value, datatype,
                                       seqno = 1)
    result = TradableProcessorParameter.new(name: name, value: value,
               data_type: datatype, sequence_number: seqno)
    result.tradable_processor_specification = tp_spec
    result.save
    result
  end

  # If a block is passed in, the tradables for 'symbols' will first be
  # tracked (and saved to DB), the block will be executed, and then the
  # same tradables will untracked - the result of the block will be
  # returned.  If not block is passed in, the tradables for 'symbols' are
  # set to tracked (i.e., tradable_symbol.track!).
  def self.track_tradables(symbols)
    result = nil
    TradableSymbol.transaction do
      symbols.each do |s|
        ts = TradableSymbol.find_by_symbol(s)
        if ts.nil? then
          puts "Error: row not found for '#{s}' [#{self.class}::#{__method__}]"
        else
          ts.track!
#          ts.save
        end
      end
    end
    if block_given? then
      result = yield
      # If a block was passed in, assume the caller wants to un-track the
      # specified tradables after the block is executed.
      TradableSymbol.transaction do
        symbols.each do |s|
          ts = TradableSymbol.find_by_symbol(s)
          if ts.nil? then
            puts "Error: row not found for '#{s}' " +
              "[#{self.class}::#{__method__}]"
          else
            ts.untrack!
#            ts.save
          end
        end
      end
    end
    result
  end

end
