
%w{app/model_facilities test test/models test/helpers
library/mas_client}.each do |path|
  $LOAD_PATH << "#{Rails.root}/#{path}"
end

require 'time_period_type_constants'
require 'period_type_constants'
require 'analysis_specification'
require 'model_helper'

class EODMonitoringSetup
  attr_reader :symbols

  def execute
    puts "I am #{self.class}"
    analysis_setup
    $analysis_spec = AnalysisSpecification.new([$analysis_user], symbols,
                                               true, false)
  end

  private

  SETUP_USER     = 'eod-admin@test.org'

  def initialize(symbols)
    @symbols = symbols
  end

  def analysis_setup
    $analysis_user = User.find_by_email_addr(SETUP_USER)
    if $analysis_user.nil? then
      $analysis_user = ModelHelper::new_user_saved(SETUP_USER)
    end
    $analysis_client = MasClientTools::mas_client(user: $analysis_user,
                                             next_port: false)
    $analysis_spec = AnalysisSpecification.new([$analysis_user], symbols,
                                               false, true)
  end
end
