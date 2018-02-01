require "bundler/gem_tasks"
require "rake/testtask"
require "rubocop/rake_task"

task :default => [:test]

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.test_files = FileList['test/**/*_test.rb'] - FileList["test/deprecation/*_test.rb"]
  test.verbose = true
end

Rake::TestTask.new(:testdep) do |test|
  test.libs << 'test'
  test.test_files = FileList["test/deprecation/*_test.rb"]
  test.verbose = true
end

RuboCop::RakeTask.new
