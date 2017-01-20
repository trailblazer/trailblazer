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
    test/operation/callback_test.rb
    test/operation/resolver_test.rb
    test/operation/dsl/contract_test.rb

    test/docs/*_test.rb
    }]

  if RUBY_VERSION == "1.9.3"
    test_files = test_files - %w{test/docs/dry_test.rb test/docs/auto_inject_test.rb}
  end

  test.test_files = test_files #- ["test/docs/rescue_test.rb"]
  test.verbose = true
end
