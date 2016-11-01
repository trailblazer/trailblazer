require "test_helper"

# self["pipetree"] = ::Pipetree[
#       Trailblazer::Operation::New,
#       # SetupParams,
#       Trailblazer::Operation::Model::Build,
#       Trailblazer::Operation::Model::Assign,
#       Trailblazer::Operation::Call,
#     ]

class PipetreeTest < Minitest::Spec
  Song = Struct.new(:title)

  class Create < Trailblazer::Operation
    include Builder
    include Pipetree # this will add the functions, again, unfortunately. definitely an error source.
  end

  it { Create["pipetree"].inspect.must_equal %{[>>Build,>>New,>>Call,>>New,>>Call]} }

  #---
  # playground
  require "trailblazer/operation/policy"
  require "trailblazer/operation/guard"

  class Edit < Trailblazer::Operation
    include Builder
    include Policy::Guard
    include Contract
    include Model

    LogBreach = ->(input, options) { input.log_breach! }

    self.< LogBreach, after: Policy::Evaluate

    model Song
    policy ->(*) { self["user.current"] }

    def log_breach!
      self["breach"] = true
    end

    def process(params)
      self["my.valid"] = true
    end
  end

  puts Edit["pipetree"].inspect(style: :rows)

  it { Edit["pipetree"].inspect.must_equal %{[>>Build,>>New,>Model::Build,&Policy::Evaluate,<LogBreach,>>Call]} }
  # valid case.
  it {
    result = Edit.({}, "user.current" => true)
    result["my.valid"].must_equal true
    result["breach"].must_equal nil
  }
  # beach! i mean breach!
  it {
    result = Edit.({})
    result["my.valid"].must_equal nil
    result["breach"].must_equal true
  }
end
