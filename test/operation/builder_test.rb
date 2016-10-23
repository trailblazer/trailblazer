require "test_helper"
require "trailblazer/operation/resolver"

class BuilderTest < Minitest::Spec
  class A < Trailblazer::Operation
    include Pipetree
    extend Builder

    builds ->(options) {
      return P if options[:params] == { id:1 } && options[:skills]["user.current"] == Module
    }

    self["pipetree"] = ::Pipetree[
      Trailblazer::Operation::Build,
      # SetupParams,
      # Call,
    ]

    class P < self; end
  end

  it { A.({ id: 1 }, { "user.current" => Module }).must_equal A::P }
  it { A.({ id: 1 }).must_equal A }
end
