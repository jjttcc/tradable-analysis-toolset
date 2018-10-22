require "test_helper"

module ModelHelper

  GOOD_ARGS1 = {:email_addr => 'user1@example.org', :password => 'eggfoobar',
                :password_confirmation => 'eggfoobar'}
  GOOD_ARGS2 = {:email_addr => 'tester@professional-testers.org',
                :password => 'barfoobing',
                :password_confirmation => 'barfoobing'}
  BAD_EMAIL1 = {:email_addr => 'tester@professional#testers.org'}

  # A new user, not saved
  def self.new_user(e)
    result = User.new(GOOD_ARGS1.merge(:email_addr => e))
    result
  end

  # A new user, saved
  def self.new_user_saved(e)
    result = User.new(GOOD_ARGS1.merge(:email_addr => e))
    result.save!
    result
  end

  # A new EventBasedTrigger for user 'user'
  def self.new_eb_trigger(active = false)
    result = EventBasedTrigger.create(active: active)
    result
  end

  # A new AnalysisProfile for user 'user'
  def self.new_profile_for_user(user, name)
    result = AnalysisProfile.create(name: name)
    user.analysis_profiles << result
    result
  end

  # A new AnalysisProfile for user 'user'
  def self.new_profile_for_schedule(schedule, name)
    result = AnalysisProfile.create(name: name)
    schedule.analysis_profiles << result
    result
  end

  # A new AnalysisSchedule for 'user' (and 'trigger', if not nil)
  def self.new_schedule_for(user, sched_name, trigger)
    result = user.analysis_schedules.create(name: sched_name)
    if trigger != nil then
      trigger.analysis_schedules << result
    end
    result
  end

  # A new EventGenerationProfile, attached to 'prof' (AnalysisProfile)
  def self.evgen_profile_for(prof, enddt, period_secs)
    result = prof.event_generation_profiles.create(end_date: enddt,
        analysis_period_length_seconds: period_secs)
    result
  end

  # A new TradableProcessorSpecification, attached to 'prof' (AnalysisProfile)
  def self.tradable_proc_spec_for(evgen_prof, proc_id, proc_name, ptype)
    result = evgen_prof.tradable_processor_specifications.create(
      processor_id: proc_id, processor_name: proc_name, period_type: ptype)
    result
  end

  # A new TradableProcessorParameter, attached to 'tp_spec'
  # (TradableProcessorSpecification)
  def self.tradable_proc_parameter_for(tp_spec, name, value, datatype,
                                       seqno = 1)
    result = tp_spec.tradable_processor_parameters.create(name: name,
      value: value, data_type: datatype, sequence_number: seqno)
    result
  end

end
