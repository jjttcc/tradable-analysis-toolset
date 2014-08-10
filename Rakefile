#!/usr/bin/env rake
# vim: expandtab ts=2 sw=2
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

TradableAnalysisToolset::Application.load_tasks

Rake::TestTask.new do |t|
  t.libs = ["lib", "test"]
  t.name = "test:external"
  t.warning = true
  t.test_files = FileList['test/external/*_test.rb']
end

Rake::TestTask.new("test:all") do |t|
  t.libs = ["lib", "test"]
  t.warning = true
  t.test_files = FileList['test/**/*_test.rb']
end
