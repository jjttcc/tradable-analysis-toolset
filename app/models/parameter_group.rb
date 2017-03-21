class ParameterGroup < ApplicationRecord
  belongs_to :user
  validates :user_id, presence: true
  has_many   :tradable_processor_parameters, :dependent => :destroy

  public

  def self.parameters_by_uid_group_and_proc_name(uid, group, procname)
    result = []
    trproc = self.tradable_processor_by_name(procname)
    if ! trproc.nil? then
      group = ParameterGroup.find_by_user_id_and_name(uid, group)
$log.debug("[pbugpn] group: #{group.inspect}")
$log.debug("[pbugpn] trproc: #{trproc.inspect}")
      result = group.tradable_processor_parameters.select do |p|
$log.debug("p.tradable_processor_id: #{p.tradable_processor_id}")
        p.tradable_processor_id == trproc.id
      end
    end
    result
  end

  def self.tradable_processor_by_name(name)
    result = nil
    if ! defined? @@tradable_processor_by_name then
      @@tradable_processor_by_name = {}
    end
    result = @@tradable_processor_by_name[name]
    if result == nil then
      result = TradableProcessor.find_by_name(name)
      if ! result.nil? then
        @@tradable_processor_by_name[name] = result
      end
    end
    result
  end

=begin
  def self.tradable_processor_parameters_by_proc_name(pname)
    query = 'select distinct * from ' +
      'tradable_processor_parameters tpp, tradable_processors tp, ' +
      'parameter_groups pg where tp.name = ? and ' +
      'tpp.tradable_processor_id = tp.id and tpp.parameter_group_id = pg.id'
$log.debug("query: #{query}")
    results = ParameterGroup.find_by_sql([query, pname])
$log.debug("PG tppbpn results: #{results.inspect}")
    pg = results[0]
$log.debug("pg.tpp: #{pg.tradable_processor_parameters.inspect}")
    pg.tradable_processor_parameters
  end

  def self.tradable_processor_parameters_by_proc_name(pname)
    query = 'select * from ' +
      'tradable_processor_parameters tpp, tradable_processors tp, ' +
      'parameter_groups pg where tp.name = "' + "#{pname}" '" and ' +
#      'parameter_groups pg where tp.name = ? and ' +
      'tpp.tradable_processor_id = tp.id and tpp.parameter_group_id = pg.id'
$log.debug("query: #{query}")
#    result = ParameterGroup.find_by_sql(query, [pname])
    result = ParameterGroup.find_by_sql(query)
$log.debug("PG tppbpn result: #{result.inspect}")
#Post.joins(:taggings).where('taggings.tag_id = ?', tag_id)
  end
=end

end
