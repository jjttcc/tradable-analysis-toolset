class ParameterGroup < ApplicationRecord
  belongs_to :user
  validates :user_id, presence: true
  has_many   :tradable_processor_parameters, :dependent => :destroy

  public

  def self.parameters_by_uid_group_and_proc_name(uid, group, procname)
    result = []
    trproc = TradableProcessor.tradable_processor_by_name(procname)
    if ! trproc.nil? then
      group = find_by_user_id_and_name(uid, group)
      result = group.tradable_processor_parameters.select do |p|
        p.tradable_processor_id == trproc.id
      end
    end
    result
  end

end
