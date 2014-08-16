# == Schema Information
#
# Table name: mas_sessions
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  mas_session_key :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  data            :text
#

require "test_helper"
require_relative 'model_helper'

class MasSessionTest < ActiveSupport::TestCase
  include ModelHelper
  include PeriodTypeConstants

  def mas_session
    @mas_session ||= MasSession.new
  end

  def test_create_session
    user = ModelHelper::new_user('mas-session-test@tests.org')
    user.save
    client = MasClientTools::new_mas_client
    msession = user.build_mas_session(mas_session_key: client.session_key)
    assert msession.valid?, 'mas session is valid'
    assert MasSession.find_by_mas_session_key(msession.id) == nil,
      'mas session not yet stored'
    msession.save
    assert MasSession.find_by_mas_session_key(msession.mas_session_key) ==
      msession, 'stored mas session found'
    client = MasClientTools::new_mas_client(session: msession)
    assert client.session_key == msession.mas_session_key.to_s,
      'session key integrity'
    client.logout
    assert client.session_key.nil?, 'logged out1'
    assert ! client.logged_in, 'logged out2'
  end

  def test_session_data
    the_data = "simple data test"
    orig_data = the_data.dup
    user = ModelHelper::new_user('mas-session-data-test@tests.org')
    user.save
    client = MasClientTools::new_mas_client
    msession = user.build_mas_session(mas_session_key: client.session_key)
    msession.data = the_data
    assert msession.valid?, 'mas session with data is valid'
    msession.save
    the_data << " - more stuff"
    client = MasClientTools::new_mas_client(session: msession)
    assert client.mas_session.data != the_data,
      'session-data with side effect - no match'
    assert client.mas_session.data == orig_data, 'session data as expected'
    client.logout
  end

end
