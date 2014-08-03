
class PeriodTypeSpec < ActiveRecord::Base
  include ActiveModel::Validations

  belongs_to :user
  attr_accessible :start_date, :end_date, :period_type_id
  validates_with PeriodTypeSpecValidator

  public

  def period_type_name
    PeriodTypeConstants.name_for[period_type_id]
  end

end
