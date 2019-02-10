
desc 'end-of-day data retrieval test'
task :test_eod, [:channel, :symbols] do |task, args|
  require "#{Rails.root}/test/services/test_eod"
  puts "rails env: #{ENV['RAILS_ENV']}"
  puts "args.channel: #{args.channel}"
  puts "args.symbols: #{args.symbols}"
  if args.symbols.count > 0 then
    TestEOD.new(args.symbols, args.channel)
  end
end
