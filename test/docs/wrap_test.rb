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

    step Rescue { |pipe|
      step Model[ Song, :find ]
      step Contract::Build[ constant: MyContract ]
    }
    step Contract::Validate[]
    step Persist[ method: :sync ]
  end

  it { Create.( id: 1, title: "Prodigal Son" )["contract.default"].model.inspect.must_equal %{#<struct RescueTest::Song id=1, title="Prodigal Son">} }
  it { Create.( id: nil ).inspect("model").must_equal %{<Result:false [nil] >} }
end
