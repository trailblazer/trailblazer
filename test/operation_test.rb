require 'test_helper'

require 'trailblazer/operation'

module Comparable
  # only used for test.
  def ==(b)
    self.class == b.class
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

    def process(params)
      model = Object
      validate(params, model)
    end
  end

  let (:contract) { Operation::Contract.new }

  # contract is inferred from self::Contract.
  it { Operation.run(true).must_equal ["local true", contract] }

  # only return contract when ::call
  it { Operation.call(true).must_equal contract }
  it { Operation[true].must_equal contract }

  # ::[] raises exception when invalid.
  it do
    exception = assert_raises(Trailblazer::Operation::InvalidContract) { Operation[false] }
    exception.message.must_equal "Op just calls #to_s on Errors!"
  end

  # ::run without block returns result set
  it { Operation.run(true).must_equal  ["local true", contract] }
  it { Operation.run(false).must_equal [false, contract] }

  # ::run with block returns contract.
  # valid executes block.
  it "block" do
    outcome = nil
    res = Operation.run(true) do
      outcome = "true"
    end
    # @outcome ||= false # not executed.

    outcome.must_equal "true" # block was executed.
    res.must_equal contract
  end

  # invalid doesn't execute block.
  it "block, invalid" do
    outcome = nil
    res = Operation.run(false) do
      outcome = "true"
    end

    outcome.must_equal nil # block was _not_ executed.
    res.must_equal contract
  end
end


class OperationTest < MiniTest::Spec
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
      params || invalid!(params)
    end
  end

  # ::run
  it { OperationWithoutValidateCall.run(Object).must_equal [true, Object] }
  # ::[]
  it { OperationWithoutValidateCall[Object].must_equal(Object) }
  # ::run with invalid!
  it { OperationWithoutValidateCall.run(nil).must_equal [false, nil] }
  # ::run with block, invalid
  it do
    OperationWithoutValidateCall.run(false) { @outcome = "true" }.must_equal false
    @outcome.must_equal nil
  end
  # ::run with block, valid
  it do
    OperationWithoutValidateCall.run(true) { @outcome = "true" }.must_equal true
    @outcome.must_equal "true"
  end
  # TODO: test contract yielding


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
