# vim: expandtab ts=2 sw=2
require 'faker'

namespace :db do
  desc "Fill database with sample data"
  email_base = 'tat-user'
  start_date = DateTime.new(2013, 1, 1)
  task :populate => :environment do
    Rake::Task['db:reset'].invoke
    100.times do |n|
      eaddr = "#{email_base}-#{n+1}@users.org"
      password = "foofoofoo"
      u = User.create!(:email_addr => eaddr,
                   :password => password,
                   :password_confirmation => password)
      if n == 0   # Force user 1 to be admin.
        u.toggle!(:admin)
        u.save
      end
    end
    (1..6).each do |uid|
      user = User.find_by_id(uid)
      PeriodTypeSpec::VALID_CATEGORY.keys.each do |category|
        PeriodTypeConstants::ids.each do |id|
          end_date = nil
          if id == PeriodTypeConstants::QUARTERLY_ID
            end_date = DateTime.yesterday
          end
          user.period_type_specs.create!(:period_type_id => id,
                                         :start_date => start_date,
                                         :end_date => end_date,
                                         :category => category)
        end
      end
    end
  end
end
