require "bundler/gem_tasks"
require "rake/testtask"

task :default => [:test]
Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.test_files = FileList['test/*_test.rb']
  test.verbose = true
end

Rake::TestTask.new(:rails) do |test|
  test.libs << 'test/rails'
  test.test_files = FileList['test/rails/*_test.rb']
  test.verbose = true
end