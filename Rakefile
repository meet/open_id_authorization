require 'rake'
require 'rake/testtask'

require 'rails/generators'
require 'rails/generators/rails/app/app_generator'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = 'test/*_test.rb'
end
task :test => :create_example_app

task :create_example_app do
  # Create dummy Rails app for testing...
  PWD = File.expand_path(Dir.pwd)
  begin
    Rails::Generators::AppGenerator.start [ 'example_app', '--quiet' ], :destination_root => File.dirname(__FILE__)
  ensure
    FileUtils.cd PWD
  end
  # ... and schedule it for destruction
  at_exit { FileUtils.rm_r File.expand_path('example_app', File.dirname(__FILE__)) }
end
