# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

############################ TEST DATA ONLY ###################################

if ENV['RAILS_ENV'] == "test"
#!!!!!?:   require 'period_type_constants'
#!!!!!?:   connection = ActiveRecord::Base.connection()
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

############################ REFERENCE DATA ###################################
require 'csv'
SYM = 'symbol'; NAME = 'name'

def load_tradable_entities
  entities = {}
  converter = lambda { |header| header.downcase }
  csv_text = File.read(Rails.root.join('db','allusstocks.csv'))
  csv = CSV.parse(csv_text, :headers => true, header_converters: converter)
  i=1
  csv.each do |row|
    hashed_row = row.to_hash
    if entities.has_key?(row[SYM]) then
      $stderr.puts "duplicate key found on line #{i}"
    else
      entities[row[SYM]] = TradableEntity.new(
        symbol: row[SYM].strip, name: row[NAME].strip)
    end
    i += 1
  end
  TradableEntity.transaction do
    entities.each do |key, value|
      value.save!
    end
  end
end

if TradableEntity.find_by_symbol('IBM').nil? then
  puts "loading tradable_entities table"
  load_tradable_entities
end
