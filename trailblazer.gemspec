# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trailblazer/version'

Gem::Specification.new do |spec|
  spec.name          = "trailblazer"
  spec.version       = Trailblazer::VERSION
  spec.authors       = ["Nick Sutterer"]
  spec.email         = ["apotonick@gmail.com"]
  spec.description   = %q{A high-level, modular architecture for Rails with domain and form objects, view models, twin decorators and representers.}
  spec.summary       = %q{A new architecture for Rails.}
  spec.homepage      = "http://www.trailblazerb.org"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "actionpack", '>= 3.0.0' # this framework works on Rails.
  spec.add_dependency "representable", ">= 2.1.1", "<2.3.0" # Representable::apply.
  spec.add_dependency "reform", ">= 1.2.0"
  spec.add_dependency "uber", ">= 0.0.10" # no builder inheritance.

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  # spec.add_development_dependency "minitest-spec-rails" # TODO: can anyone make this work (test/rails).
  spec.add_development_dependency "responders"
  spec.add_development_dependency "sidekiq", "~> 3.1.0"
  spec.add_development_dependency "rails"
  spec.add_development_dependency "sqlite3"
end
