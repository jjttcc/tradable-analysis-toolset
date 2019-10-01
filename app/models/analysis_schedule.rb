=begin
name: varchar (NOT NULL)
# Is this schedule currently used? (i.e., false implies: self is unused/ignored)
active: boolean (NOT NULL)
trigger_type: varchar
trigger_id: integer
user_id: integer (NOT NULL)
=end

# Objects that are used to schedule, by means of an external "trigger"
# object, a series of 'request_analysis' calls to the MAS server -
# configured via 0 or more analysis_profiles - and the processing of the
# resulting analysis-event data returned by the server.
class AnalysisSchedule < ApplicationRecord
  include Contracts::DSL

  public

  #####  Access

  belongs_to :trigger, polymorphic: true
  belongs_to :user
  has_many   :analysis_profiles, as: :analysis_client, dependent: :destroy

  # (many-to-many: User <=> NotificationAddress:)
#### (test/experiment!!!!!! [may not be permanent]): ####
  has_many   :address_assignments, as: :address_user
  has_many   :notification_addresses, :through => :address_assignments

  #####  Boolean queries

  # Is this schedule currently in use - i.e., active?
  def active?
    self.active
  end

end
