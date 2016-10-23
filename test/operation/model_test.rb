require "test_helper"
require "trailblazer/operation/model"

class ModelTest < Minitest::Spec
  Song = Struct.new(:title)

  class Create < Trailblazer::Operation
    include Pipetree

    include Model
    model Song, :create

    self["pipetree"] = ::Pipetree[
      Trailblazer::Operation::Build,
      # SetupParams,
      Trailblazer::Operation::Model::Build,
      Trailblazer::Operation::Model::Assign,
      Trailblazer::Operation::Call,
    ]
  end

  # :create new.
  it { Create.({})["model"].inspect.must_equal %{#<struct ModelTest::Song title=nil>} }

  # TODO: add all the other tests from compat/model_test.rb.

  # TODO: override #model! etc. and add params?
end
