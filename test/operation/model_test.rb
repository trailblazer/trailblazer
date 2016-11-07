require "test_helper"
require "trailblazer/operation/model"

class ModelTest < Minitest::Spec
  Song = Struct.new(:id) do
    def self.find(id); new(id) end
    def self.find_by(id:nil); id.nil? ? nil : new(id) end
  end

  #---
  # use Model semantics, no customizations.
  class Create < Trailblazer::Operation
    self.| Model[ Song, :create ]
  end

  # :create new.
  it { Create.({})["model"].inspect.must_equal %{#<struct ModelTest::Song id=nil>} }

  class Update < Create
    self.~ Model[:update] # DISCUSS: do we need the ~ operator?
  end

  # :find it
  it { Update.({ id: 1 })["model"].inspect.must_equal %{#<struct ModelTest::Song id=1>} }

  #- inheritance
  it { Update["pipetree"].inspect.must_equal %{[>>operation.new,&model.build]} }

  # override #model with Model included.
  class Upsert < Create
    def model!(params); params.to_s end
  end

  it { Upsert.(id: 9)["model"].must_equal %{{:id=>9}} }

  #---
  # :find_by, exceptionless.
  class Find < Trailblazer::Operation
    self.| Model[Song, :find_by]
    self.| Call

    def process(*); self["x"] = true end
  end

  # can't find model.
  #- result object, model
  it do
    Find.(id: nil)["result.model"].failure?.must_equal true
    Find.(id: nil)["x"].must_equal nil
    Find.(id: nil).failure?.must_equal true
  end

  #- result object, model
  it do
    Find.(id: 9)["result.model"].success?.must_equal true
    Find.(id: 9)["x"].must_equal true
    Find.(id: 9)["model"].inspect.must_equal %{#<struct ModelTest::Song id=9>}
  end

  #---
  # override #model!, without any Model inclusions.
  class Delete < Trailblazer::Operation
    self.| :model!
    def model!(params); params.to_s end
  end

  it { Delete.(id: 1)["model"].must_equal %{{:id=>1}} }

  #---
  # creating the model before operation instantiation (ex Model::External)
  class Show < Create
    extend Model::BuildMethods # FIXME: how do we communicate that and prevent the include from Model[] ?
    self.| Model[Song, :update], before: "operation.new"
  end

  it { Show.({id: 1})["model"].inspect.must_equal %{#<struct ModelTest::Song id=1>} }


  # TODO: with builder!

  #---
  # provide your own object ModelBuilder that includes BuilderMethods.
  # this tests that BuildMethods is interchangable and acts as an example how to  decouple
  # the model building from the operation.
  class Index < Trailblazer::Operation
    # DISCUSS: help user to do this kind of behavior?
    # model Song, :find # ModelBuilder can read this via skills that we pass to it.
    self["model.class"] = Song
    self["model.action"] = :find

    # this is to be able to use BuildModel.
    class ModelBuilder
      include Trailblazer::Operation::Model::BuildMethods # #instantiate_model and so on.
      alias_method :call, :model!

      def initialize(skills); @delegator = skills  end

      extend Uber::Delegates
      delegates :@delegator, :[]
    end

    self.> ->(input, options) { options["model"] = ModelBuilder.new(options).(options["params"]); input }, after: "operation.new"
  end

  it { Index.(id: 1)["model"].inspect.must_equal %{#<struct ModelTest::Song id=1>} }
end
