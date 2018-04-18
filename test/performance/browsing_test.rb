require 'test_helper'

class BrowsingTest < ActionDispatch::PerformanceTest
  # Refer to the documentation for all available options
  # self.profile_options = { :runs => 5, :metrics => [:wall_time, :memory]
  #                          :output => 'tmp/performance', :formats => [:flat] }

=begin
# Avoid this error (minitest 5.11.3):
#/home/jtc/.rvm/gems/ruby-2.3.0/gems/minitest-5.11.3/lib/minitest.rb:964:
#in `run_one_method': BrowsingTest#run _must_ return a Result (RuntimeError)
#
  def test_homepage
    get '/'
  end
=end
end
