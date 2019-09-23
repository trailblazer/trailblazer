lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trailblazer/version'

Gem::Specification.new do |spec|
  spec.name          = "trailblazer"
  spec.version       = Trailblazer::Version::VERSION
  spec.authors       = ["Nick Sutterer"]
  spec.email         = ["apotonick@gmail.com"]
  spec.description   = %q{A high-level architecture introducing new abstractions such as operations and control flow, form objects and policies.}
  spec.summary       = %q{A high-level architecture for Ruby and Rails.}
  spec.homepage      = "http://trailblazer.to"
  spec.license       = "LGPL-3.0"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|doc)/})
  end
  spec.test_files    = `git ls-files -z test`.split("\x0")
  spec.require_paths = ["lib"]

  spec.add_dependency "trailblazer-macro", ">= 2.1.0", "< 2.2.0"
  spec.add_dependency "trailblazer-macro-contract", ">= 2.1.0", "< 2.2.0"
  spec.add_dependency "trailblazer-operation" # TODO: why do we need this here?

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"

  spec.required_ruby_version = '>= 2.1.0'
end
