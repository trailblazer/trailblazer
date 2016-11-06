require "bundler/gem_tasks"
require "rake/testtask"

task :default => [:test]

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  # test.test_files = FileList['test/**/*_test.rb']
  test.test_files = FileList[%w{test/operation/guard_test.rb
    test/operation/policy_test.rb
    test/operation/builder_test.rb
    test/operation/model_test.rb
    test/operation/contract_test.rb


    }]
  test.verbose = true
end
