require "test_helper"

describe AnalysisProfile do
  let(:analysis_profile) { AnalysisProfile.new }

  it "must be valid" do
    value(analysis_profile).must_be :valid?
  end
end
