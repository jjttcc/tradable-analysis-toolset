ENV["RAILS_ENV"] = "test"
require File.expand_path("../../config/environment", __FILE__)
require "rails/test_help"
require "minitest/rails"
require "minitest/rails/capybara"

# To add Capybara feature tests add `gem "minitest-rails-capybara"`
# to the test group in the Gemfile and uncomment the following:
# require "minitest/rails/capybara"

# Uncomment for awesome colorful output
#require "minitest/pride"

class ActiveSupport::TestCase
    # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
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

end
