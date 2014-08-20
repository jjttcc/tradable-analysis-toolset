class PeriodTypeSpecAdapter
  include Contracts::DSL

  public ###  Access

  post :effective_date do |result|
    result == period_type_spec.effective_start_date end
  def start_date
#!!!!!!debugging - remove soon:
puts "PeriodTypeSpecAdapter.start_date:"
puts "real start date: #{period_type_spec.start_date.to_date}"
puts "false start date: #{period_type_spec.effective_start_date.to_date}\n"
    period_type_spec.effective_start_date
  end

  post :effective_date do |result|
    result == period_type_spec.effective_end_date end
  def end_date
#!!!!!!debugging - remove soon:
puts "PeriodTypeSpecAdapter.end_date:"
if period_type_spec.end_date != nil
puts "real end date: #{period_type_spec.end_date.to_date}"
puts "false end date: #{period_type_spec.effective_end_date.to_date}"
end
    period_type_spec.effective_end_date
  end

  def period_type_name
    period_type_spec.period_type_name
  end

  alias :period_type :period_type_name

  def period_type_id
    period_type_spec.period_type_id
  end

  def category
    period_type_spec.category
  end

  def user
    period_type_spec.user
  end

  public ###  Comparison

  def ==(other_spec)
    other_spec == period_type_spec
  end

  public ###  Status report

  def for_analysis?
    period_type_spec.for_analysis?
  end

  def invariant
    period_type_spec.invariant
  end

  private

  attr_accessor :period_type_spec

  def initialize(target)
    @period_type_spec = target
  end

end
