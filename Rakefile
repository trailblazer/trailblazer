require "bundler/gem_tasks"
require "rake/testtask"

task :default => [:build]
default_task = Rake::Task[:build]

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.test_files = FileList['test/*_test.rb', "test/operation/**/*_test.rb"]
  test.verbose = true
end

# this how the rails test must be run: BUNDLE_GEMFILE=gemfiles/Gemfile.rails bundle exec rake rails
Rake::TestTask.new(:rails) do |test|
  test.libs << 'test/rails'
  test.test_files = FileList['test/rails/*_test.rb']
  test.verbose = true
end

rails_task = Rake::Task["rails"]
test_task = Rake::Task["test"]
default_task.enhance { test_task.invoke }
default_task.enhance { rails_task.invoke }
