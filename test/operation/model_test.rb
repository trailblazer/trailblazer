require "test_helper"
require "trailblazer/operation/model"

class ModelTest < Minitest::Spec
  Song = Struct.new(:id) do
    def self.find(id); new(id) end
  end

  class Create < Trailblazer::Operation
    include Model
    model Song, :create
  end

  # :create new.
  it { Create.({})["model"].inspect.must_equal %{#<struct ModelTest::Song id=nil>} }

  class Update < Create
    action :find
  end

  # :find it
  it { Update.({ id: 1 })["model"].inspect.must_equal %{#<struct ModelTest::Song id=1>} }

  # TODO: add all the other tests from compat/model_test.rb.

  # TODO: override #model! etc. and add params?

  #---
  # creating the model before operation instantiation (ex Model::External)
  class Show < Create
    extend Model::DSL
    model Song, :update

    self.| Model::Build, before: New
    self.| Model::Assign, after: Model::Build


    # self["pipetree"] = ::Pipetree[
    #   Call,
    #   Trailblazer::Operation::Model::Build,
    #   Trailblazer::Operation::Model::Assign,
    #   Trailblazer::Operation::New,
    # ]
  end

  it { Show.({id: 1})["model"].inspect.must_equal %{#<struct ModelTest::Song id=1>} }

  # TODO: with builder!
end
