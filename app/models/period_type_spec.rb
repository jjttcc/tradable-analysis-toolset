# == Schema Information
#
# Table name: period_type_specs
#
#  id             :integer          not null, primary key
#  period_type_id :integer          not null
#  start_date     :datetime
#  end_date       :datetime
#  user_id        :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  category       :string(255)
#

class PeriodTypeSpec < ApplicationRecord
  include ActiveModel::Validations
  include Contracts::DSL

  belongs_to :user
  validates_with PeriodTypeSpecValidator
  after_save :clear_caches

  default_scope -> { order('period_type_id', updated_at: :desc) }

  ## Valid category values
  LONG_TERM = 'long-term'
  SHORT_TERM = 'short-term'
  VALID_CATEGORY = { LONG_TERM => true, SHORT_TERM => true }

  public ###  Access

  # The start-date updated with respect to the current date
  pre :start_date_exists do ! start_date.nil? end
  post :result_exists do |result| result != nil end
  def effective_start_date
    if @eff_start_date.nil?
      @eff_start_date = adjusted_datetime(start_date)
    end
    @eff_start_date
  end

  # The end-date updated with respect to the current date - nil iff
  # end_date == nil
  def effective_end_date
    if end_date.nil?
      if ! @eff_end_date.nil?
        @eff_end_date = nil
      end
    elsif @eff_end_date.nil?
      @eff_end_date = adjusted_datetime(end_date)
    end
    @eff_end_date
  end

  # The name corresponding to period_type_id
  def period_type_name
    PeriodTypeConstants.name_for[period_type_id]
  end

  alias :period_type :period_type_name

  public ###  Status report

  # Is 'self' to be used for analysis?
  def for_analysis?
    category == SHORT_TERM
  end

  def invariant
    implies(category != nil, VALID_CATEGORY[category])
  end

  private

  def datetime_at_midnight(date)
    result = Time.new(date.year, date.month, date.day, 0)
  end

  def adjusted_datetime(dt)
    today = datetime_at_midnight(DateTime.now.in_time_zone(updated_at.zone))
    correction_interval = updated_at.to_datetime.to_date -
      dt.to_datetime.to_date
    result = (today.to_date - correction_interval).to_datetime
    result = result.change({
      :hour => dt.hour,
      :min => dt.min,
      :sec => dt.sec
    })
  end

  def clear_caches
    @eff_start_date, @eff_end_date = nil, nil
  end

end
