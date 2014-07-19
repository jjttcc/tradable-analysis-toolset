# == Schema Information
#
# Table name: users
#
#  id                 :integer          not null, primary key
#  email_addr         :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  encrypted_password :string(255)
#

require "test_helper"

class UserTest < ActiveSupport::TestCase

  GOOD_ARGS1 = {:email_addr => 'user1@example.org', :password => 'eggfoobar',
                :password_confirmation => 'eggfoobar'}
  GOOD_ARGS2 = {:email_addr => 'tester@professional-testers.org',
                :password => 'barfoobing',
                :password_confirmation => 'barfoobing'}
  BAD_EMAIL1 = {:email_addr => 'tester@professional#testers.org'}

  def valid_user
    if @valid_user == nil
      @valid_user = User.create!(GOOD_ARGS1)
    end
    @valid_user
  end

  def invalid_user
    @invalid_user ||= User.new
  end

  def bad_email_users
    @bad_email_users ||= [
      User.new(GOOD_ARGS1.merge(BAD_EMAIL1)),
      User.new(GOOD_ARGS1.merge(:email_addr => '*tester@what?')),
      User.new(GOOD_ARGS1.merge(:email_addr => '@what.org')),
      User.new(GOOD_ARGS1.merge(:email_addr => '@@bomb.org')),
      User.new(GOOD_ARGS1.merge(:email_addr => 'la-bomba@la-bomba@.org')),
    ]
  end

  def duplicate_emails
    @duplicate_emails ||= [
      User.new(GOOD_ARGS1.merge(:email_addr => 'ordinary@boring.org')),
      User.new(GOOD_ARGS1.merge(:email_addr => 'ordinary@boring.org')),
      User.new(GOOD_ARGS1.merge(:email_addr => 'Ordinary@BORING.org')),
    ]
  end

  ### Basic validation ###

  def test_valid
    assert valid_user.valid?
  end

  def test_invalid
    assert (not invalid_user.valid?)
  end

  def test_bad_email
=begin
    Note: I found two regexes that appear reasonable for email validation:
    /\b[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}\z/)
      and:
    /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/)
=end
    bad_email_users.each do |u|
      assert(! u.valid?, "invalid email address not detected")
    end
  end

  def test_duplicate_email
    duplicate_emails[0].save
    assert ! duplicate_emails[1].valid?, "non-unique email address"
  end

  def test_duplicate_email_with_different_case
    duplicate_emails[0].save
    assert ! duplicate_emails[2].valid?, "non-unique email address"
  end

  ### Password ###

  def test_has_password_attribute
    assert valid_user.respond_to?(:password), "responds to 'password'"
  end

  def test_has_password_conf_attribute
    assert valid_user.respond_to?(:password_confirmation)
  end

  ### Password validation ###

  def new_user(e)
    result = User.new(GOOD_ARGS1.merge(:email_addr => e))
    result
  end

  def test_no_password
    pwlessu = new_user('foo@foo.org')
    pwlessu.password = ''
    pwlessu.password_confirmation = ''
    assert(! pwlessu.valid?, "invalid without password")
  end

  def test_valid_pw_conf
    u = new_user('foo2@foo.org')
    u.password = 'foobarfoo'
    u.password_confirmation = 'barbarbar'
    assert(! u.valid?, "invalid without matching password_conf")
  end

  def test_reject_short_pw
    u = new_user('foo3@foo.org')
    shortpw = 'foo'
    u.password = shortpw
    u.password_confirmation = shortpw
    assert(! u.valid?, "short passwords invalid")
  end

  def test_reject_long_pw
    u = new_user('foo3@foo.org')
    longpw = 'foo' + 'X' * 62
    u.password = longpw
    u.password_confirmation = longpw
    assert(! u.valid?, "long passwords invalid")
  end

  ### Password encryption ###

  def setup
    @pw_user ||= User.create!(GOOD_ARGS2)
  end

  def test_has_encrypted_password
    assert @pw_user.respond_to?(:encrypted_password)
  end

  def test_encrypted_pw_set
    assert(@pw_user.encrypted_password != nil &&
           @pw_user.encrypted_password.length > 0, "encrypted password set")
  end

  ### Password-related ###

  def test_has_password_match_query
    assert @pw_user.respond_to?(:password_matches?),
      "has password_matches query"
  end

  def test_for_password_match
    assert @pw_user.password_matches?('barfoobing'), "pw should match"
  end

  def test_negative_password_match
    assert ! @pw_user.password_matches?('abcdcba'), "pw should NOT match"
  end

  def test_has_salt
    assert @pw_user.respond_to?(:salt), "has 'salt' attribute"
  end

  ### User/Password authentication

  def test_has_auth_method
    assert User.respond_to?(:authenticate), "has 'authenticate' method"
  end

  def test_email_pw_mismatch
    assert User.authenticate(GOOD_ARGS2[:email_addr], 'invalid_pw') == nil
  end

  def test_wrong_email
    assert User.authenticate('barbar@foo.org', GOOD_ARGS2[:password]) == nil
  end

  def test_good_auth
    assert User.authenticate(GOOD_ARGS2[:email_addr],
                             GOOD_ARGS2[:password]) == @pw_user, "good auth"
  end

end
