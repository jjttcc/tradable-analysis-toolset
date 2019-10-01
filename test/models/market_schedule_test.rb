require "test_helper"

describe MarketSchedule do
  let(:market_schedule) { MarketSchedule.new(
    core_start_time: '1030',
    core_end_time: '1030'
  )
  }

  it "must be valid" do
    value(market_schedule).must_be :valid?
  end

  it "valid core_hours" do
    # (I.e., 'core_hours' doesn't throw an exception.)
    market_schedule.core_hours(DateTime.now)
  end
end
