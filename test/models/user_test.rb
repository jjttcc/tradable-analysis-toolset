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

  def valid_user
    @valid_user ||= User.new(:email_addr => 'tester@professional-testers.org')
  end

  def invalid_user
    @invalid_user ||= User.new
  end

  def bad_email_users
    @bad_email_users ||= [
      User.new(:email_addr => 'tester@professional#testers.org'),
      User.new(:email_addr => '*tester@what?'),
      User.new(:email_addr => '@what.org'),
      User.new(:email_addr => '@@bomb.org'),
      User.new(:email_addr => 'la-bomba@la-bomba@.org'),
    ]
  end

  def duplicate_emails
    @duplicate_emails ||= [
      User.new(:email_addr => 'ordinary@boring.org'),
      User.new(:email_addr => 'ordinary@boring.org'),
      User.new(:email_addr => 'Ordinary@BORING.org'),
    ]
  end

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
      assert (not u.valid?)
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

end
