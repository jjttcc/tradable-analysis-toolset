require "test_helper"

describe AnalysisRun do
  let(:analysis_run) { AnalysisRun.new }

  it "must be valid" do
    value(analysis_run).must_be :valid?
  end
end
