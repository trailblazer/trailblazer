require 'test_helper'

require 'trailblazer/operation'


class FlowTest < MiniTest::Spec
  class Operation
    def run(params)
      [params]
    end
  end

  it "no block" do
    res = Trailblazer::Flow.flow(true, Operation.new)
    res.must_equal [true, nil]
  end

  it "no block, invalid" do
    res = Trailblazer::Flow.flow(false, Operation.new)
    res.must_equal [false, nil]
  end

  it "block" do
    @outcome = "nil"
    res = Trailblazer::Flow.flow(true, Operation.new) do
      @outcome = "true"
    end
    @outcome ||= false # not executed.

    @outcome.must_equal "true" # block was executed.
    res.must_equal nil # !!! assert something better.
  end

  it "block, invalid" do
    res = Trailblazer::Flow.flow(false, Operation.new) do
      @outcome = "true"
    end
    @outcome ||= false # not executed.

    @outcome.must_equal false # block was _not_ executed.
    res.must_equal nil # !!! assert something better.
  end
end




class OperationTest < MiniTest::Spec
  class Contract #< Reform::Form
    def initialize(*)
    end
    def validate(params)
      params
    end
  end

  require 'ostruct'
  class Operation < Trailblazer::Operation
    extend Flow

    def run(params)
      model = OpenStruct.new
      validate(model, params, Contract)
    end
  end


  it "no block" do
    res = Operation.flow(true)
    res.must_equal [true, OpenStruct.new]
  end

  it "no block, invalid" do
    res = Operation.flow(false)
    res.must_equal [false, OpenStruct.new]
  end


  it do
   #@result = "nil"

    Trailblazer::Flow.flow(true, Operation)  do |model| # usually, model _is_ the Contract/Form.
      @result = true # executed in real context.
    end
    # usually, you'd use return in the block?
    @result ||= false

    @result.must_equal true
  end

  it do
    #@result = "nil"

    Trailblazer::Flow.flow(false, Operation) do |model| # usually, model _is_ the Contract/Form.
      @result = true # executed in real context.
    end
    # usually, you'd use return in the block?
    @result ||= false
    @result.must_equal false
  end
end



class OperationRunTest < MiniTest::Spec
  class Operation < Trailblazer::Operation
    class Contract #< Reform::Form
      def initialize(*)
      end
      def validate(params)
        "local #{params}"
      end
    end

    extend Flow

    def run(params)
      model = Object
      validate(model, params)
    end
  end

  # contract is inferred from self::Contract.
  it { Operation.run(true).must_equal ["local true", Object] }
end


class SelfmadeOperationIncludingFlow < MiniTest::Spec
  class Operation
    extend Trailblazer::Flow # gives us Operation.flow.

    def self.run(params) # rename to #call
      new.run(params)
    end

    def run(params)
      [params, Object] # done by validate
    end
  end

  it do
    Operation.flow(true).must_equal [true, Object]
  end

  it "no block, invalid" do
    res = Operation.flow(false)
    res.must_equal [false, Object]
  end

  # with block => we don't need result boolean!
  it "block" do
    @outcome = "nil"
    res = Operation.flow(true) do
      @outcome = "true"
    end
    @outcome ||= false # not executed.

    @outcome.must_equal "true" # block was executed.
    res.must_equal Object
  end

  it "block, invalid" do
    res = Operation.flow(false) do
      @outcome = "true"
    end
    @outcome ||= false # not executed.

    @outcome.must_equal false # block was _not_ executed.
    res.must_equal Object
  end
end
