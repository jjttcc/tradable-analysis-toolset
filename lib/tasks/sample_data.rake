# vim: expandtab ts=2 sw=2
require 'faker'

namespace :db do
  desc "Fill database with sample data"
  email_base = 'tat-user'
  task :populate => :environment do
    Rake::Task['db:reset'].invoke
    100.times do |n|
      eaddr = "#{email_base}-#{n+1}@users.org"
      password = "drowssap"
      u = User.create!(:email_addr => eaddr,
                   :password => password,
                   :password_confirmation => password)
      if n == 0   # Force user 1 to be admin.
        u.toggle!(:admin)
        u.save
      end
    end
  end
end
