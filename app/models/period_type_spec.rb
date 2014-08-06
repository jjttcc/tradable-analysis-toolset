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

  belongs_to :user
  attr_accessible :start_date, :end_date, :period_type_id
  validates_with PeriodTypeSpecValidator

  default_scope :order => 'period_type_id, period_type_specs.updated_at DESC'

  public

  def period_type_name
    PeriodTypeConstants.name_for[period_type_id]
  end

end
