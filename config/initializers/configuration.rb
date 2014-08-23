
Rails.configuration.mas_host = 'localhost'
if ENV['TATPORT']
  Rails.configuration.mas_port1 = ENV['TATPORT']
else
  Rails.configuration.mas_port1 = 5441
end
Rails.configuration.mas_port = Rails.configuration.mas_port1
Rails.configuration.mas_port2 = 5442

Rails.configuration.earliest_year = 1950
Rails.configuration.latest_year = DateTime.now.year + 10
