require "test_helper"

describe AnalysisEvent do
  let(:analysis_event) { AnalysisEvent.new }

  it "must be valid" do
    value(analysis_event).must_be :valid?
  end
end
