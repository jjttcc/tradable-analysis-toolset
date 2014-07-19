# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  email_addr :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require "test_helper"

class UserTest < ActiveSupport::TestCase

  GOOD_ARGS1 = {:email_addr => 'user1@example.org', :password => 'foobar',
                :password_confirmation => 'foobar'}
  GOOD_ARGS2 = {:email_addr => 'tester@professional-testers.org',
                :password => 'barfoo', :password_confirmation => 'barfoo'}
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
    result = User.create!(GOOD_ARGS1.merge(:email_addr => e))
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
    u.password = 'foo'
    u.password_confirmation = 'bar'
    assert(! u.valid?, "invalid without matching password_conf")
  end

end
