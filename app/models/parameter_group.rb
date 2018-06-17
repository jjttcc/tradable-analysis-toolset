=begin
CREATE TABLE "parameter_groups" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL
"name" varchar
"user_id" integer
"created_at" datetime NOT NULL
"updated_at" datetime NOT NULL);
CREATE INDEX "index_parameter_groups_on_name" ON "parameter_groups" ("name");
CREATE INDEX "index_parameter_groups_on_user_id" ON "parameter_groups" ("user_id");
=end

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
