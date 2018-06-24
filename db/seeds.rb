# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

require 'period_type_constants'

connection = ActiveRecord::Base.connection()

if ENV['RAILS_ENV'] == "test"
  require_relative '../test/test_constants'

  admin_email, nonadmin_email = TestConstants::ADMIN_EMAIL,
    TestConstants::NONADMIN_EMAIL
  admin_pw, nonadmin_pw = TestConstants::ADMIN_PW, TestConstants::NONADMIN_PW
  if User.find_by_email_addr(admin_email) == nil
    #### Ensure both an 'admin' and a non-admin user resides in the DB.
    user = User.create!(:email_addr => admin_email,
                        :password => admin_pw,
                        :password_confirmation => admin_pw)
    user.toggle!(:admin)
    user = User.create!(:email_addr => nonadmin_email,
                        :password => nonadmin_pw,
                        :password_confirmation => nonadmin_pw)
    a = User.find_by_email_addr(admin_email)
    u = User.find_by_email_addr(nonadmin_email)
    if a.nil? or u.nil?
      throw "failed to save admin or non-admin"
    end
  end
end
