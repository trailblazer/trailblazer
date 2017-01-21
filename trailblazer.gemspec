lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trailblazer/version'

Gem::Specification.new do |spec|
  spec.name          = "trailblazer"
  spec.version       = Trailblazer::VERSION
  spec.authors       = ["Nick Sutterer"]
  spec.email         = ["apotonick@gmail.com"]
  spec.description   = %q{A high-level architecture for Ruby introducing new abstractions such as operations, form objects or policies.}
  spec.summary       = %q{A high-level architecture for Ruby and Rails.}
  spec.homepage      = "http://trailblazer.to"
  spec.license       = "LGPL-3.0"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "trailblazer-operation", ">= 0.0.12", "< 0.1.0"
  spec.add_dependency "reform", ">= 2.2.0", "< 3.0.0"
  spec.add_dependency "declarative"

  spec.add_development_dependency "activemodel" # for Reform::AM::V

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "nokogiri"

  spec.add_development_dependency "roar"
  # spec.required_ruby_version = '>= 1.9.3'
  spec.required_ruby_version = '>= 2.0.0'
end
