# /lib/tasks/documentation.rake
# The original version of this file came from:
# http://stackoverflow.com/questions/36804473/rake-aborted-dont-know-how-to-build-task-docapp
# Note: If you need to force rake to regenerate docs, do:
#   rake --build-all doc:app

require 'rdoc/task'

namespace :doc do
  RDoc::Task.new("app") { |rdoc|
    rdoc.rdoc_dir = 'doc/app'
    rdoc.template = ENV['template'] if ENV['template']
    rdoc.title = ENV['title'] || 'Rails Application Documentation'
    rdoc.options << '--line-numbers'
    rdoc.options << '--charset' << 'utf-8'
    rdoc.rdoc_files.include('README.md')
    rdoc.rdoc_files.include('app/**/*.rb')
    rdoc.rdoc_files.include('lib/**/*.rb')
    rdoc.rdoc_files.include('library/mas_client/**/*.rb')
    rdoc.rdoc_files.include('library/utility/**/*.rb')
  }
  Rake::Task['doc:app'].comment = "Generate docs for the app -- also available doc:rails, doc:guides (options: TEMPLATE=/rdoc-template.rb, TITLE=\"Custom Title\")"
end
