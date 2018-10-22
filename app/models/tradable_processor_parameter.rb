=begin
#!!!!!NOTE: This spec is out of date - remove it or fix it!!!!!!
CREATE TABLE "tradable_processor_parameters" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL
"name" varchar
"value" varchar
"data_type" varchar
"tradable_processor_id" integer
"created_at" datetime NOT NULL
"updated_at" datetime NOT NULL);
CREATE INDEX "index_tradable_processor_parameters_on_tradable_processor_id" ON "tradable_processor_parameters" ("tradable_processor_id");
=end

VALID_PARAMETER_TYPES = ['integer', 'real']

# Parameters containing a value, to be used as settings for an indicator or
# an analyzer, for the MAS server - e.g.: MACD settings of 12, 26, 9 (3
# parameters)
class TradableProcessorParameter < ApplicationRecord
  #!!!!implement this:!!! belongs_to :tradable_processor
  #Add this??: validates :tradable_processor_id, presence: true #!!!!!
#!!!TO-DO: document sequence_number
  validates :name, presence: true, length: { maximum: 255 }
  validates :value, presence: true, length: { maximum: 255 }
  validates :data_type, presence: true, length: { maximum: 7 }, 
   :inclusion => { :in      => VALID_PARAMETER_TYPES,
                   :message => "%{value} is not a valid data type spec" }
  validates_each :value do |record, attr, value|
    result = true
    msg = nil
    if record.data_type == VALID_PARAMETER_TYPES[0] && value =~ /\./ then
      result = false
    elsif value !~ /(^(\d+)(\.)?(\d+)?)|(^(\d+)?(\.)(\d+))/ then
      result = false
    end
    if ! result then
      record.errors.add(attr, " (#{value}) must be of type #{record.data_type}")
    end
   result
  end
end
