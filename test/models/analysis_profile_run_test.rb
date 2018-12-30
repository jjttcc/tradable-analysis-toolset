require "test_helper"

describe AnalysisProfileRun do
  let(:analysis_profile_run) { AnalysisProfileRun.new }

  it "must be valid" do
    value(analysis_profile_run).must_be :valid?
  end
end
