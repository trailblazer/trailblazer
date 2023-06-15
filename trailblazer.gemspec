lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trailblazer/version'

Gem::Specification.new do |spec|
  spec.name          = "trailblazer"
  spec.version       = Trailblazer::Version::VERSION
  spec.authors       = ["Nick Sutterer"]
  spec.email         = ["apotonick@gmail.com"]
  spec.summary       = %q{Ruby framework for structuring your business logic.}
  spec.homepage      = "https://trailblazer.to"
  spec.license       = "LGPL-3.0"
  spec.metadata      = {
    "bug_tracker_uri"   => "https://github.com/trailblazer/trailblazer/issues",
    "changelog_uri"     => "https://github.com/trailblazer/trailblazer/blob/master/CHANGES.md",
    "documentation_uri" => "https://trailblazer.to/docs",
    "homepage_uri"      => "https://trailblazer.to/",
    "mailing_list_uri"  => "https://trailblazer.zulipchat.com/",
    "source_code_uri"   => "https://github.com/trailblazer/trailblazer",
    "wiki_uri"          => "https://github.com/trailblazer/trailblazer/wiki"
  }
  
  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|doc)/})
  end
  spec.test_files    = `git ls-files -z test`.split("\x0")
  spec.require_paths = ["lib"]

  spec.add_dependency "trailblazer-macro",          ">= 2.1.15", "< 2.2.0"
  spec.add_dependency "trailblazer-developer",      ">= 0.1.0", "< 0.2.0"
  spec.add_dependency "trailblazer-macro-contract", ">= 2.1.4", "< 2.2.0"
  spec.add_dependency "trailblazer-operation",      ">= 0.9.0", "< 1.0.0"
  spec.add_dependency "trailblazer-activity-dsl-linear", ">= 1.2.3", "< 1.3.0" # this can be removed at some point.

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "minitest-line"
  spec.add_development_dependency "dry-validation"

  spec.required_ruby_version = '>= 2.5.0'
end
