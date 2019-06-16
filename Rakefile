require "bundler/gem_tasks"
require "rake/testtask"

task :default => %i[test]

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.test_files = FileList['test/**/*_test.rb'] - FileList["test/deprecation/*_test.rb"]
  test.verbose = true
end
