require "test_helper"

class ModelTest < Minitest::Spec
  Song = Struct.new(:id) do
    def self.find(id); new(id) end
    def self.find_by(id:nil); id.nil? ? nil : new(id) end
  end

  #---
  # use Model semantics, no customizations.
  class Create < Trailblazer::Operation
    step Model Song, :new
  end

  # :new new.
  it { Create.({})["model"].inspect.must_equal %{#<struct ModelTest::Song id=nil>} }

  class Update < Create
    step Model( Song, :find ), override: true
  end

  # :find it
  it { Update.({ id: 1 })["model"].inspect.must_equal %{#<struct ModelTest::Song id=1>} }

  #- inheritance
  it { Update["pipetree"].inspect.must_equal %{[>operation.new,>model.build]} }

  #---
  # :find_by, exceptionless.
  class Find < Trailblazer::Operation
    step Model Song, :find_by
    step :process

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

  # #---
  # # creating the model before operation instantiation (ex Model::External)
  # class Show < Create
  #   extend Model::BuildMethods # FIXME: how do we communicate that and prevent the include from Model[] ?
  #   step Model( Song, :update ), before: "operation.new"
  # end

  # it { Show.({id: 1})["model"].inspect.must_equal %{#<struct ModelTest::Song id=1>} }
end
