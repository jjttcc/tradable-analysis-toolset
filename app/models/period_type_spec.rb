# == Schema Information
#
# Table name: period_type_specs
#
#  id             :integer          not null, primary key
#  period_type_id :integer
#  start_date     :datetime
#  end_date       :datetime
#  user_id        :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#


class PeriodTypeSpec < ActiveRecord::Base
  include ActiveModel::Validations
  include Contracts::DSL

  belongs_to :user
  attr_accessible :start_date, :end_date, :period_type_id, :category
  validates_with PeriodTypeSpecValidator

  default_scope :order => 'period_type_id, period_type_specs.updated_at DESC'

  ## Valid category values
  LONG_TERM = 'long-term'
  SHORT_TERM = 'short-term'
  VALID_CATEGORY = { LONG_TERM => true, SHORT_TERM => true }

  public

  def period_type_name
    PeriodTypeConstants.name_for[period_type_id]
  end

  # Is 'self' to be used for analysis?
  def for_analysis?
    category == SHORT_TERM
  end

  def invariant
    implies(category != nil, VALID_CATEGORY[category])
  end

end
