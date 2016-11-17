lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trailblazer/version'

Gem::Specification.new do |spec|
  spec.name          = "trailblazer"
  spec.version       = Trailblazer::VERSION
  spec.authors       = ["Nick Sutterer"]
  spec.email         = ["apotonick@gmail.com"]
  spec.description   = %q{A high-level, modular architecture for Ruby framworks with domain and form objects, view models, twin decorators and representers.}
  spec.summary       = %q{A high-level architecture for Ruby and Rails.}
  spec.homepage      = "http://trailblazer.to"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]


  spec.add_dependency "uber", ">= 0.0.15", "< 0.1.0"
  spec.add_dependency "reform", ">= 2.0.0", "< 3.0.0"
  spec.add_dependency "declarative"

  spec.add_development_dependency "activemodel" # for Reform::AM::V

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "database_cleaner"

  spec.add_development_dependency "roar"
end
