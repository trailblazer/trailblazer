git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

source 'https://rubygems.org'

# Specify your gem's dependencies in trailblazer.gemspec
gemspec

gem "multi_json"

gem "dry-auto_inject"
gem "dry-matcher"
gem "dry-validation"

if ENV['USE_LOCAL_GEMS']
  gem "reform", path: "../reform"
  gem "reform-rails", path: "../reform-rails"
  gem "trailblazer-operation", path: "../trailblazer-operation"
  gem "trailblazer-macro", path: "../trailblazer-macro"
  gem "trailblazer-macro-contract", path: "../trailblazer-macro-contract"
  gem "trailblazer-activity", path: "../trailblazer-activity"
  gem "trailblazer-context", path: "../trailblazer-context"
else
  gem "reform", github: "trailblazer/reform"
  gem "reform-rails", github: "trailblazer/reform-rails"
  gem "trailblazer-operation", github: "trailblazer/trailblazer-operation"
  gem "trailblazer-macro", github: "trailblazer/trailblazer-macro"
  gem "trailblazer-macro-contract", github: "trailblazer/trailblazer-macro-contract"
  gem "trailblazer-activity", github: "trailblazer/trailblazer-activity"
  gem "trailblazer-context", github: "trailblazer/trailblazer-context"
end


gem "minitest-line"

gem "rubocop", require: false
