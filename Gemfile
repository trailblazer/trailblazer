source 'https://rubygems.org'

# Specify your gem's dependencies in trailblazer.gemspec
gemspec

gem "activesupport"#, "~> 4.2.0"

gem "multi_json"

gem "dry-auto_inject"
gem "dry-matcher"
gem "dry-validation"

if ENV['USE_LOCAL_GEMS']
  gem "trailblazer-operation", path: "../trailblazer-operation"
  gem "trailblazer-macro", path: "../trailblazer-macro"
  gem "trailblazer-macro-contract", path: "../trailblazer-macro-contract"
  gem "trailblazer-activity", path: "../trailblazer-activity"
  gem "reform", path: "../reform"
  gem "reform-rails", path: "../reform-rails"
else
  gem "reform"
  gem "reform-rails"
  gem "trailblazer-operation", github: "trailblazer/trailblazer-operation"
  gem "trailblazer-macro", github: "trailblazer/trailblazer-macro"
  gem "trailblazer-macro-contract", github: "trailblazer/trailblazer-macro-contract"
  gem "trailblazer-activity", github: "trailblazer/trailblazer-activity"
end


gem "minitest-line"

gem "rubocop", require: false
