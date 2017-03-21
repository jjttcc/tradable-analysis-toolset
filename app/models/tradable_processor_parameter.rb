VALID_PARAMETER_TYPES = ['integer', 'real']

# Parameters containing a value, to be used as settings for an indicator or
# an analyzer, for the MAS server - e.g.: MACD settings of 12, 26, 9 (3
# parameters)
class TradableProcessorParameter < ApplicationRecord
  belongs_to :parameter_group
  validates :parameter_group_id, presence: true
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
