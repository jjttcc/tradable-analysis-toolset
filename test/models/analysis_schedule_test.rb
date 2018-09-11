require "test_helper"

describe AnalysisSchedule do
  let(:analysis_schedule) { AnalysisSchedule.new }

  it "must be valid" do
    value(analysis_schedule).must_be :valid?
  end
end
