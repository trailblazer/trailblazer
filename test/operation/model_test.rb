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

  puts "***** Update"
  class Update < Create
    puts self["__activity__"].circuit.instance_variable_get(:@map).size
    step Model( Song, :find ), override: true
    puts self["__activity__"].circuit.instance_variable_get(:@map).size
  end
  puts Update["__task_wraps__"].inspect
  puts "::"
  puts Update["__activity__"].inspect

  # :find it
  it { Update.({ id: 1 })["model"].inspect.must_equal %{#<struct ModelTest::Song id=1>} }

  #- inheritance
  it { Trailblazer::Operation::Inspect.(Update).must_equal %{[>model.build]} }

  #---
  # :find_by, exceptionless.
  class Find < Trailblazer::Operation
    step Model Song, :find_by
    step :process

    def process(options, **); options["x"] = true end
  end

  # can't find model.
  #- result object, model
  it do
    Find.(id: nil)["result.model"].failure?.must_equal true
    Find.(id: nil)["x"].must_be_nil
    Find.(id: nil).failure?.must_equal true
  end

  #- result object, model
  it do
    Find.(id: 9)["result.model"].success?.must_equal true
    Find.(id: 9)["x"].must_equal true
    Find.(id: 9)["model"].inspect.must_equal %{#<struct ModelTest::Song id=9>}
  end
end
