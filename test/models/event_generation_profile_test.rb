require "test_helper"

describe EventGenerationProfile do
  let(:event_generation_profile) {
    EventGenerationProfile.new(analysis_period_length_seconds: 86400)
  }

  it "must be valid" do
    value(event_generation_profile).must_be :valid?
  end
end
