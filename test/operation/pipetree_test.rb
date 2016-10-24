require "test_helper"

# self["pipetree"] = ::Pipetree[
#       Trailblazer::Operation::New,
#       # SetupParams,
#       Trailblazer::Operation::Model::Build,
#       Trailblazer::Operation::Model::Assign,
#       Trailblazer::Operation::Call,
#     ]

class PipetreeTest < Minitest::Spec
  class Create < Trailblazer::Operation
    include Pipetree
  end

  it { Create["pipetree"].inspect("#").must_equal %{ 0) New# 1) Call} }
end
