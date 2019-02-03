AUTO_RUN_OFF = true
KEEP_DATA = true
require_relative '../models/notification_address_test.rb'
require_relative '../helpers/analysis_specification'

class ServicesTest < MiniTest::Test
  include Contracts::DSL

  TESTPORT = 5441
  TARGET_SYMBOL   = 'ibm'
  ANA_USER     = 'mas-client-testc@test.org'

  def setup
  end

  def teardown
  end

  def test_db_fork
    require "rake"
    Rails.application.load_tasks
    Rake::Task['test_db_fork'].invoke
    assert true, 'no exception thrown'
  rescue Exception => e
    assert false, "exception caught - db-fork test  failed: #{e}"
  end

end
