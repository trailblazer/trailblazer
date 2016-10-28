require "test_helper"
require "trailblazer/operation/model"

class ModelTest < Minitest::Spec
  Song = Struct.new(:id) do
    def self.find(id); new(id) end
  end

  #---
  # use Model semantics, no customizations.
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

  # override #model with Model included.
  class Upsert < Create
    def model!(params); params.to_s end
  end

  it { Upsert.(id: 9)["model"].must_equal %{{:id=>9}} }


  #---
  # override #model!, without any Model inclusions.
  class Delete < Trailblazer::Operation
    include Model::Builder
    def model!(params); params.to_s end
  end

  it { Delete.(id: 1)["model"].must_equal %{{:id=>1}} }

  #---
  # creating the model before operation instantiation (ex Model::External)
  class Show < Create
    extend Model::DSL
    extend Model::BuildMethods
    model Song, :update

    self.| Model::Build, before: New
  end

  it { Show.({id: 1})["model"].inspect.must_equal %{#<struct ModelTest::Song id=1>} }

  # TODO: with builder!

  #---
  # provide your own object ModelBuilder that includes BuilderMethods.
  # this tests that BuildMethods is interchangable and acts as an example how to  decouple
  # the model building from the operation.
  class Index < Trailblazer::Operation
    extend Model::DSL
    model Song, :find # ModelBuilder can read this via skills that we pass to it.

    # this is to be able to use BuildModel.
    class ModelBuilder
      include Trailblazer::Operation::Model::BuildMethods # #instantiate_model and so on.
      alias_method :call, :model!

      def initialize(skills); @delegator = skills  end

      extend Uber::Delegates
      delegates :@delegator, :[]
    end

    self.| ->(input, options) { options["model"] = ModelBuilder.new(options).(options["params"]); input }, after: New
  end

  it { Index.(id: 1)["model"].inspect.must_equal %{#<struct ModelTest::Song id=1>} }
end
