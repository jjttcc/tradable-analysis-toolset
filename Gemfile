source 'https://rubygems.org'
# vim: expandtab ts=2 sw=2

gem 'rails', '3.2.13'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'sqlite3'
#gem 'will_paginate', '3.0.pre'
gem 'will_paginate'
gem 'yahoo-finance'
gem 'gon'


# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'
# For design-by-contract support:
gem 'ruby_contracts'

group :development, :test do
  gem 'minitest'
  gem "minitest-rails", "~> 1.0"
  gem 'factory_girl_rails', '1.0'
  gem 'minitest-rails-capybara'
  gem 'capybara_minitest_spec'  # for capybara integration and spec matchers
  gem 'launchy'
  gem 'turn'                    # for report prettification
end

group :development do
  gem 'faker', '0.3.1'
  gem 'annotate'
end

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'debugger'
