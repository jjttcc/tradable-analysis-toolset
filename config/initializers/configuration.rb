
Rails.configuration.mas_host = 'localhost'
if ENV['TATPORT']
  Rails.configuration.mas_port1 = ENV['TATPORT']
else
  Rails.configuration.mas_port1 = 5441
end
Rails.configuration.mas_ports = [Rails.configuration.mas_port1, 5442,
                                 5443, 5444]

Rails.configuration.earliest_year = 1950
Rails.configuration.latest_year = DateTime.now.year + 10
