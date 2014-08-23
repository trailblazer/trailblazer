require 'test_helper'

require 'trailblazer/operation'

module Comparable
  # only used for test.
  def ==(b)
    self.class == b.class
  end
end


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



# Operation with Contract and #process
class OperationTest < MiniTest::Spec
  class Contract
    def initialize(*)
    end
    def validate(params)
      params
    end

    include Comparable
  end

  require 'ostruct'
  class Operation < Trailblazer::Operation
    extend Flow

    def process(params)
      model = OpenStruct.new
      validate(params, model, Contract)
    end
  end


  it "no block" do
    res = Operation.flow(true)
    res.must_equal [true, Contract.new]
  end

  it "no block, invalid" do
    res = Operation.flow(false)
    res.must_equal [false, Contract.new]
  end


  # use Flow directly.
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
        return false if params == false # used in ::[] with exception test.
        "local #{params}"
      end

      def errors
        Struct.new(:to_s).new("Op just calls #to_s on Errors!")
      end

      include Comparable
    end

    extend Flow

    def process(params)
      model = Object
      validate(params, model)
    end
  end

  # contract is inferred from self::Contract.
  it { Operation.run(true).must_equal ["local true", Operation::Contract.new] }

  # only return contract when ::call
  it { Operation.call(true).must_equal Operation::Contract.new }
  it { Operation[true].must_equal Operation::Contract.new }

  # ::[] raises exception when invalid.
  it do
    exception = assert_raises(Trailblazer::Operation::InvalidContract) { Operation[false] }
    exception.message.must_equal "Op just calls #to_s on Errors!"
  end
end


class OperationRunWithoutContractTest < MiniTest::Spec
  class Operation < Trailblazer::Operation
    def process(params)
      validate(Object, params)
    end
  end

  # contract is inferred from self::Contract.
  it { assert_raises(NameError) { Operation.run(true) } }


  # #process and no validate.
  class OperationWithoutValidateCall < Trailblazer::Operation
    def process(params)
      params
    end
  end

  # ::run
  it { OperationWithoutValidateCall.run(Object).must_equal [true, Object] }
  # ::[]
  it { OperationWithoutValidateCall[Object].must_equal(Object) }


  # manually setting @valid
  class OperationWithManualValid < Trailblazer::Operation
    def process(params)
      @valid = false
      params
    end
  end

  # ::run
  it { OperationWithManualValid.run(Object).must_equal [false, Object] }
  # ::[]
  it { OperationWithManualValid[Object].must_equal(Object) }


  # re-assign params
  class OperationReassigningParams < Trailblazer::Operation
    def process(params)
      params = params[:title]
      params
    end
  end

  # ::run
  it { OperationReassigningParams.run({:title => "Day Like This"}).must_equal [true, "Day Like This"] }


  # #invalid!
  class OperationCallingInvalid < Trailblazer::Operation
    def process(params)
      return 1 if params
      invalid!(2)
    end
  end

  it { OperationCallingInvalid.run(true).must_equal [true, 1] }
  it { OperationCallingInvalid.run(nil).must_equal [false, 2] }


  # unlimited arguments for ::run and friends.
  class OperationReceivingLottaArguments < Trailblazer::Operation
    def process(model, params)
      [model, params]
    end
  end

  it { OperationReceivingLottaArguments.run(Object, {}).must_equal([true, [Object, {}]]) }


  # TODO: experimental.
  # ::contract to avoid running #validate.
  class ContractOnlyOperation < Trailblazer::Operation
    class Contract
      def initialize(model)
        @_model = model
      end
      attr_reader :_model
    end

    def process(params)
      @object = Object # arbitraty init code.

      validate(params, Object) do
        raise "this should not be run."
      end
    end
  end

  it { ContractOnlyOperation.contract({})._model.must_equal Object }


  # ::[] raising exception when invalid.
  class ReturnContract
    def initialize(*)
    end
    def validate(params)
      params
    end

    include Comparable
  end

  class OperationUsingValidate < Trailblazer::Operation
    def process(params)

    end
  end
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
