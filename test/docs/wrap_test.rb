require "test_helper"

class WrapTest < Minitest::Spec
  Song = Struct.new(:id, :title) do
    def self.find(id)
      id.nil? ? raise : new(id)
    end
  end

  class Create < Trailblazer::Operation
    class MyContract < Reform::Form
      property :title
    end

    step Wrap ->(pipe, operation, options) {
      begin
        pipe.(operation, options)
      rescue => exception
        options["result.model.find"] = "argh! because #{exception.class}"
        false
      end } { |pipe|
      step Model[ Song, :find ]
      step Contract::Build[ constant: MyContract ]
    }
    step Contract::Validate[]
    step Persist[ method: :sync ]
  end

  it { Create.( id: 1, title: "Prodigal Son" )["contract.default"].model.inspect.must_equal %{#<struct WrapTest::Song id=1, title="Prodigal Son">} }
  it { Create.( id: nil ).inspect("result.model.find").must_equal %{<Result:false [\"argh! because RuntimeError\"] >} }
end

class RescueTest < Minitest::Spec
  Song = Struct.new(:id, :title) do
    def self.find(id)
      id.nil? ? raise : new(id)
    end
  end

  class Create < Trailblazer::Operation
    class MyContract < Reform::Form
      property :title
    end

    step Rescue {
      step Model[ Song, :find ]
      step Contract::Build[ constant: MyContract ]
    }
    step Contract::Validate[]
    step Persist[ method: :sync ]
  end

  it { Create.( id: 1, title: "Prodigal Son" )["contract.default"].model.inspect.must_equal %{#<struct RescueTest::Song id=1, title="Prodigal Son">} }
  it { Create.( id: nil ).inspect("model").must_equal %{<Result:false [nil] >} }


  #---
  # nested raise (i hope people won't use this but it works)
  A = Class.new(RuntimeError)
  Y = Class.new(RuntimeError)

  class NestedInsanity < Trailblazer::Operation
    step Rescue {
      step ->(options) { options["a"] = true }
      step Rescue {
        step ->(options) { options["y"] = true }
        step ->(options) { raise Y if options["raise-y"] }
        step ->(options) { options["z"] = true }
      }
      step ->(options) { options["b"] = true }
      step ->(options) { raise A if options["raise-a"] }
      step ->(options) { options["c"] = true }
      self.< ->(options) { options["inner-err"] = true }
    }
    step ->(options) { options["e"] = true }
    self.< ->(options) { options["outer-err"] = true }
  end

  it { NestedInsanity["pipetree"].inspect.must_equal %{[>>operation.new,&Rescue:63,>:75,<RescueTest::NestedInsanity:76]} }
  it { NestedInsanity.({}).inspect("a", "y", "z", "b", "c", "e", "inner-err", "outer-err").must_equal %{<Result:true [true, true, true, true, true, true, nil, nil] >} }
  it { NestedInsanity.({}, "raise-y" => true).inspect("a", "y", "z", "b", "c", "e", "inner-err", "outer-err").must_equal %{<Result:false [true, true, nil, nil, nil, nil, true, true] >} }
  it { NestedInsanity.({}, "raise-a" => true).inspect("a", "y", "z", "b", "c", "e", "inner-err", "outer-err").must_equal %{<Result:false [true, true, true, true, nil, nil, nil, true] >} }

  #-
  # inheritance
  class UbernestedInsanity < NestedInsanity
  end

  it { UbernestedInsanity.({}).inspect("a", "y", "z", "b", "c", "e", "inner-err", "outer-err").must_equal %{<Result:true [true, true, true, true, true, true, nil, nil] >} }
  it { UbernestedInsanity.({}, "raise-a" => true).inspect("a", "y", "z", "b", "c", "e", "inner-err", "outer-err").must_equal %{<Result:false [true, true, true, true, nil, nil, nil, true] >} }
end
