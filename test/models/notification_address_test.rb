require "test_helper"
require_relative 'model_helper'

TEST_USER_ADDR = 'address-lover@tests.org'
ADDR_NAME1  = 'label 1'
ADDR_NAME2  = 'label 2'
ADDR_NAME3  = 'label 3'
PROF_NAME = 'profile'
PROF_NAME1 = PROF_NAME
PROF_NAME2 = 'profile2'
PROF_NAME3 = 'profile3'
SCHED_NAME = 'schedule'

class NotificationAddressTest < ActiveSupport::TestCase

  def init_database_with_user
    ModelHelper::new_user_saved(TEST_USER_ADDR)
  end

  def init_database_with_user_and_address
    user = ModelHelper::new_user_saved(TEST_USER_ADDR)
    ModelHelper::new_notification_address_for_user(user, ADDR_NAME1)
  end

  def test_new
    address = NotificationAddress.new
    assert ! address.nil?, "It should NOT be nil."
    assert value(address).must_be :valid?, "It's valid."
    begin
      address.save!
      assert false, "This line (#{__LINE__}) should never be reached."
    rescue
      assert true, "DB exception expected on line (#{__LINE__})."
    end
  end

  def test_unowned_address_creation
    label = ADDR_NAME1
    user = ModelHelper::new_user_saved(TEST_USER_ADDR)
    address = ModelHelper::new_notification_address_for_user(user, label)
    assert user.notification_addresses.include?(address),
      'user has the address'
    assert address.label == label, 'address - label set.'
  end

  def test_owned_address_creation
    label = ADDR_NAME1
    user = ModelHelper::new_user_saved(TEST_USER_ADDR)
    profile = ModelHelper::new_profile_for_user(user, PROF_NAME)
    address = ModelHelper::new_notification_address_used_by([profile],
                                                            user, label)
    assert user.notification_addresses.include?(address),
      'user has the address'
    assert address.label == label, 'address - label set.'
    assert profile.notification_addresses[0] == address, 'profile owns addr'
    assert address.address_users[0] == profile, 'addr used by profile'
  end

  def test_3_used_addresses_by_3_addrusers_mix(schedule = nil,
    profile1 = nil, profile2 = nil
  )
    label1 = ADDR_NAME1
    label2 = ADDR_NAME2
    label3 = ADDR_NAME3
    prof1id, prof2id = nil, nil
    user = ModelHelper::new_user_saved(TEST_USER_ADDR)
    trigger = ModelHelper::new_eb_trigger()
    if schedule.nil? then
      schedule = ModelHelper::new_schedule_for(user, SCHED_NAME, trigger)
    end
    userid = user.id
    user.transaction do
      if profile1.nil? then
        profile1 = ModelHelper::new_profile_for_user(user, PROF_NAME1)
      end
      if profile2.nil? then
        profile2 = ModelHelper::new_profile_for_user(user, PROF_NAME2)
      end
      address1 = ModelHelper::new_notification_address_used_by(
        [profile1, schedule], user, label1)
      address2 = ModelHelper::new_notification_address_used_by(
        [profile2, schedule], user, label2)
      address3 = ModelHelper::new_notification_address_used_by(
        [profile2, schedule], user, label3)
      address2.text!
      profile1.save
      prof1id = profile1.id
      profile2.save
      prof2id = profile2.id
    end
    all_addrs = NotificationAddress.all
    addr1 = all_addrs[0]; addr2 = all_addrs[1]; addr3 = all_addrs[2]
    assert all_addrs.count == 3, 'total of 3 addresses'
    profile1 = AnalysisProfile.find_by_id(prof1id)
    profile2 = AnalysisProfile.find_by_id(prof2id)
    user = User.find_by_id(userid)
    assert profile1.notification_addresses.count == 1, 'prof1: 1 address'
    assert profile2.notification_addresses.count == 2, 'prof2: 2 addresses'
    assert schedule.notification_addresses.count == 3, 'sched: 3 addresses'
    assert user.notification_addresses.count == 3, "3 user's addresses"
    profile1.notification_addresses.each do |a|
      assert schedule.notification_addresses.include?(a),
        "schedule and profile1 should both use #{a}"
    end
    profile2.notification_addresses.each do |a|
      assert schedule.notification_addresses.include?(a),
        "schedule and profile2 should both use #{a}"
    end
    all_addrs = NotificationAddress.all
    assert all_addrs.count == 3, 'total of 3 addresses'
    return schedule, profile1, profile2
  end

end
