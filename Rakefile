require "bundler/gem_tasks"
require "rake/testtask"

task :default => [:test]

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  # test.test_files = FileList['test/**/*_test.rb']
  test_files = FileList[%w{
    test/operation/pundit_test.rb
    test/operation/model_test.rb
    test/operation/contract_test.rb
    test/operation/persist_test.rb
    test/operation/dsl/contract_test.rb

    test/docs/*_test.rb
    }]

  test.test_files = test_files #- ["test/docs/rescue_test.rb"]
  test.verbose = true
end
