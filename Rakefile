require "bundler/gem_tasks"
require "rake/testtask"

task :default => [:build]
default_task = Rake::Task[:build]

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.test_files = FileList['test/**/*_test.rb']
  test.verbose = true
end