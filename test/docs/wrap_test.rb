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

    step Wrap ->(options, *, &block) {
      begin
        block.call
      rescue => exception
        options["result.model.find"] = "argh! because #{exception.class}"
        false
      end } {
      step Model( Song, :find )
      step Contract::Build( constant: MyContract )
    }
    step Contract::Validate()
    step Persist( method: :sync )
  end

  it { Create.( id: 1, title: "Prodigal Son" )["contract.default"].model.inspect.must_equal %{#<struct WrapTest::Song id=1, title="Prodigal Son">} }
  it { Create.( id: nil ).inspect("result.model.find").must_equal %{<Result:false [\"argh! because RuntimeError\"] >} }

  #-
  # Wrap return
  class WrapReturnTest < Minitest::Spec
    class Create < Trailblazer::Operation
      step Wrap ->(options, *, &block) { options["yield?"] ? block.call : false } {
        step ->(options) { options["x"] = true }
        # ...
      }
    end

    it { Create.().inspect("x").must_equal %{<Result:false [nil] >} }
    # returns falsey means deviate to left.
    it { Create.({}, "yield?" => true).inspect("x").must_equal %{<Result:true [true] >} }
  end

  class WrapWithCallableTest < Minitest::Spec
    class MyWrapper
      extend Uber::Callable

      def self.call(options, *, &block)
        options["yield?"] ? yield : false
      end
    end

    class Create < Trailblazer::Operation
      step Wrap( MyWrapper ) {
        step ->(options) { options["x"] = true }
        # ...
      }
    end

    it { Create.().inspect("x").must_equal %{<Result:false [nil] >} }
    # returns falsey means deviate to left.
    it { Create.({}, "yield?" => true).inspect("x").must_equal %{<Result:true [true] >} }
  end

  #-
  # arguments for Wrap
  class Update < Trailblazer::Operation
    step Wrap ->(options, operation, pipe, &block) { operation["yield?"] ? block.call : false } {
      step ->(options) { options["x"] = true }
    }
  end

  it { Update.().inspect("x").must_equal %{<Result:false [nil] >} }
  it { Update.({}, "yield?" => true).inspect("x").must_equal %{<Result:true [true] >} }
end

class RescueTest < Minitest::Spec
  RecordNotFound = Class.new(RuntimeError)

  Song = Struct.new(:id, :title) do
    def self.find(id)
      raise if id == "RuntimeError!"
      id.nil? ? raise(RecordNotFound) : new(id)
    end

    def lock!
    end
  end

  class Create < Trailblazer::Operation
    class MyContract < Reform::Form
      property :title
    end

    step Rescue {
      step Model(Song, :find)
      step Contract::Build( constant: MyContract )
    }
    step Contract::Validate()
    step Persist( method: :sync )
  end

  it { Create.( id: 1, title: "Prodigal Son" )["contract.default"].model.inspect.must_equal %{#<struct RescueTest::Song id=1, title="Prodigal Son">} }
  it { Create.( id: nil ).inspect("model").must_equal %{<Result:false [nil] >} }

  #-
  # Rescue ExceptionClass, handler: ->(*) { }
  class WithExceptionNameTest < Minitest::Spec
  #
  class Create < Trailblazer::Operation
    class MyContract < Reform::Form
      property :title
    end

    step Rescue( RecordNotFound, KeyError, handler: :rollback! ) {
      step Model( Song, :find )
      step Contract::Build( constant: MyContract )
    }
    step Contract::Validate()
    step Persist( method: :sync )

    def rollback!(exception, options)
      options["x"] = exception.class
    end
  end

    it { Create.( id: 1, title: "Prodigal Son" )["contract.default"].model.inspect.must_equal %{#<struct RescueTest::Song id=1, title="Prodigal Son">} }
    it { Create.( id: 1, title: "Prodigal Son" ).inspect("x").must_equal %{<Result:true [nil] >} }
    it { Create.( id: nil ).inspect("model", "x").must_equal %{<Result:false [nil, RescueTest::RecordNotFound] >} }
    it { assert_raises(RuntimeError) { Create.( id: "RuntimeError!" ) } }
  end


  #-
  # cdennl use-case
  class CdennlRescueAndTransactionTest < Minitest::Spec
    module Sequel
      cattr_accessor :result

      def self.transaction
        yield.tap do |res|
          self.result = res
        end
      end
    end

  #
  class Create < Trailblazer::Operation
    class MyContract < Reform::Form
      property :title
    end

    step Rescue( RecordNotFound, handler: :rollback! ) {
      step Wrap ->(*, &block) { Sequel.transaction do block.call end } {
        step Model( Song, :find )
        step ->(options) { options["model"].lock! }
        step Contract::Build( constant: MyContract )
        step Contract::Validate( )
        step Persist( method: :sync )
      }
    }
    self.< :error! # handle all kinds of errors.

    def rollback!(exception, options)
      options["x"] = exception.class
    end

    def error!(options)
      options["err"] = true
    end
  end

    it { Create.( id: 1, title: "Pie" ).inspect("model", "x", "err").must_equal %{<Result:true [#<struct RescueTest::Song id=1, title=\"Pie\">, nil, nil] >} }
    # raise exceptions in Model:
    it { Create.( id: nil ).inspect("model", "x").must_equal %{<Result:false [nil, RescueTest::RecordNotFound] >} }
    it { assert_raises(RuntimeError) { Create.( id: "RuntimeError!" ) } }
    it do
      Create.( id: 1, title: "Pie" )
      Sequel.result.first.must_equal Pipetree::Flow::Right
    end
  end

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

  it { NestedInsanity["pipetree"].inspect.must_equal %{[>>operation.new,&Rescue:87,>:99,<RescueTest::NestedInsanity:100]} }
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
