ENV["RAILS_ENV"] = "test"
require File.expand_path("../../config/environment", __FILE__)
require "rails/test_help"
require "minitest/rails"
require 'minitest/reporters'
Minitest::Reporters.use!
require 'application_configuration'

# Uncomment for awesome colorful output
#require "minitest/pride"

#=============================================================================
#from:
#https://rubydoc.info/github/teamcapybara/capybara#Using_Capybara_with_Minitest
require 'capybara/rails'
require 'capybara/minitest'

class ActionDispatch::IntegrationTest
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  # Make `assert_*` methods behave like Minitest assertions
  include Capybara::Minitest::Assertions

  # Reset sessions and driver between tests
  teardown do
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end
#=============================================================================

require "#{Rails.root}/db/seeds.rb"

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in
  # alphabetical order.
  # Note: You'll currently still have to declare fixtures explicitly
  # in integration tests -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  # Return an array with 3 elements:
  #   - a hash-table of valid user-attribute settings [<good-hash>]
  #   - a hash-table of invalid user-attribute settings
  #   - A new, valid (stored in DB) User object created with <good-hash>
  def setup_test_user
    bad_attr = {:email_addr => '', :password => ''}
    good_attr = {
      :email_addr            => 'iexist@test.org',
      :password              => 'existence-is-futile',
      :password_confirmation => 'existence-is-futile',
    }
    dbuser = User.find_by_email_addr(good_attr[:email_addr])
    if dbuser == nil
      # The user is not yet in the database.
      dbuser = User.create!(good_attr)
      if dbuser == nil
        throw "Retrieval of user at #{good_attr[:email_addr]} failed."
      end
    end
    [good_attr, bad_attr, dbuser]
  end

  # Same as 'setup_test_user' except the user will have the specified email
  # address, and the invalid hash (2nd result/element) will have 'email' as
  # its email address and an empty password.
  def setup_test_user_with_eaddr(email)
    bad_attr = {:email_addr => email, :password => ''}
    good_attr = {
      :email_addr            => email,
      :password              => 'this-be-secret',
    }
    good_attr[:password_confirmation] = good_attr[:password]
    dbuser = User.find_by_email_addr(good_attr[:email_addr])
    if dbuser == nil
      # The user is not yet in the database.
      dbuser = User.create!(good_attr)
      if dbuser == nil
        throw "Retrieval of user at #{good_attr[:email_addr]} failed."
      end
    end
    [good_attr, bad_attr, dbuser]
  end

  # Go to the "sign-in" page and log 'user' in.
  def sign_in(user)
    visit signin_path
    fill_in 'Email address', :with => user.email_addr
    fill_in 'Password', :with => user.password
    click_button 'Submit'
  end

  # A valid, signed in (setup_test_user) user
  def signed_in_user
    _, _, user = setup_test_user
    sign_in(user)
    user
  end

  # A new, signed in user with the specified email address
  def signed_in_user_with_eaddr(e)
    _, _, user = setup_test_user_with_eaddr(e)
    sign_in(user)
    user
  end

  # Assume we're already on the sign-in page and attempt to log 'user' in.
  def sign_in_without_visiting(user)
    fill_in 'Email address', :with => user.email_addr
    fill_in 'Password', :with => user.password
    click_button 'Submit'
  end

  # The 'admin' user from the database
  def admin_user
    email = TestConstants::ADMIN_EMAIL
    pw = TestConstants::ADMIN_PW
    result = User.find_by_email_addr(email)
    result.password = pw
    if result == nil
      throw "Retrieval of admin user at #{email} failed."
    end
    result
  end

  # The 'non-admin' user from the database
  def non_admin_user
    email = TestConstants::NONADMIN_EMAIL
    pw = TestConstants::NONADMIN_PW
    result = User.find_by_email_addr(email)
    result.password = pw
    if result == nil
      throw "Retrieval of non-admin user at #{email} failed."
    end
    result
  end

  # The path 'pth' with locale taken into account
  def locale_path(pth)
    result = ''
    if pth == '/' then
      result = pth + I18n.locale.to_s
    else
      result = '/' + I18n.locale.to_s + pth
    end
  end

end
